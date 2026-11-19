<?php
/**
 * Mobile app REST API (CCD Raffle App — Square Tap to Pay in-person sales)
 *
 * @package CCD_Raffle
 */

defined( 'ABSPATH' ) || exit;

class CCD_Raffle_App_Api {

    /**
     * Single instance
     */
    private static $instance = null;

    /**
     * Get instance
     */
    public static function instance() {
        if ( is_null( self::$instance ) ) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Constructor
     */
    private function __construct() {
        add_action( 'rest_api_init', array( $this, 'register_routes' ) );
        // Called directly (not hooked back onto plugins_loaded) since this class is itself
        // instantiated from CCD_Raffle::init(), which already runs on plugins_loaded.
        $this->maybe_create_table();
    }

    /**
     * Table name for the idempotency record.
     */
    private static function table_name() {
        global $wpdb;
        return $wpdb->prefix . 'ccd_raffle_app_sales';
    }

    /**
     * Create/upgrade the idempotency table.
     */
    private function maybe_create_table() {
        if ( '1.0' === get_option( 'ccd_raffle_app_api_db_version' ) ) {
            return;
        }

        global $wpdb;
        $table_name      = self::table_name();
        $charset_collate = $wpdb->get_charset_collate();

        $sql = "CREATE TABLE $table_name (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            square_payment_id VARCHAR(255) NOT NULL,
            order_id BIGINT UNSIGNED NOT NULL,
            event_id BIGINT UNSIGNED NOT NULL,
            quantity INT UNSIGNED NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            UNIQUE KEY square_payment_id (square_payment_id)
        ) $charset_collate;";

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta( $sql );

        update_option( 'ccd_raffle_app_api_db_version', '1.0' );
    }

    /**
     * Register REST routes under ccd-raffle/v1
     */
    public function register_routes() {
        register_rest_route(
            'ccd-raffle/v1',
            '/events',
            array(
                'methods'             => 'GET',
                'callback'            => array( $this, 'get_events' ),
                'permission_callback' => array( $this, 'check_api_key' ),
            )
        );

        register_rest_route(
            'ccd-raffle/v1',
            '/sales',
            array(
                'methods'             => 'POST',
                'callback'            => array( $this, 'create_sale' ),
                'permission_callback' => array( $this, 'check_api_key' ),
            )
        );

        register_rest_route(
            'ccd-raffle/v1',
            '/mobile-auth',
            array(
                'methods'             => 'GET',
                'callback'            => array( $this, 'get_mobile_auth_code' ),
                'permission_callback' => array( $this, 'check_api_key' ),
            )
        );
    }

    /**
     * Permission callback shared by both routes: checks the X-CCD-Raffle-App-Key
     * header against the CCD_RAFFLE_APP_API_KEY constant defined in wp-config.php.
     * Deliberately NOT the WooCommerce REST consumer key/secret -- that key is
     * scoped to the whole store and already tied to the Printify integration.
     */
    public function check_api_key( WP_REST_Request $request ) {
        $provided = $request->get_header( 'x-ccd-raffle-app-key' );
        $expected = defined( 'CCD_RAFFLE_APP_API_KEY' ) ? CCD_RAFFLE_APP_API_KEY : '';

        if ( empty( $expected ) || empty( $provided ) || ! hash_equals( $expected, $provided ) ) {
            return new WP_Error( 'invalid_api_key', __( 'Invalid or missing API key.', 'ccd-raffle' ), array( 'status' => 401 ) );
        }

        return true;
    }

    /**
     * GET /ccd-raffle/v1/events
     * Upcoming, raffle-enabled, still-sellable events -- uses the same
     * CCD_Raffle::event_is_sellable() check the web purchase shortcode uses,
     * so the two can never drift out of sync.
     */
    public function get_events( WP_REST_Request $request ) {
        $events = get_posts(
            array(
                'post_type'      => 'tribe_events',
                'post_status'    => 'publish',
                'posts_per_page' => -1,
                'meta_query'     => array(
                    array(
                        'key'     => '_ccd_raffle_enabled',
                        'value'   => '',
                        'compare' => '!=',
                    ),
                ),
                'meta_key'       => '_EventStartDate',
                'orderby'        => 'meta_value',
                'order'          => 'ASC',
            )
        );

        $results = array();

        foreach ( $events as $event ) {
            $sellable = CCD_Raffle::event_is_sellable( $event->ID );
            if ( ! $sellable['sellable'] ) {
                continue;
            }

            $ticket_price = get_post_meta( $event->ID, '_ccd_raffle_ticket_price', true );
            $ticket_price = $ticket_price ? (float) $ticket_price : 5.0;

            $dayof_product = $this->get_dayof_product( $event->ID );

            $results[] = array(
                'event_id'         => $event->ID,
                // get_the_title() runs titles through display filters (wptexturize etc.)
                // meant for HTML pages -- those can leave literal entities like "&#8211;"
                // in the string, which is wrong for a JSON API. Decode them back to plain text.
                'title'            => html_entity_decode( get_the_title( $event->ID ), ENT_QUOTES, 'UTF-8' ),
                'start_date'       => function_exists( 'tribe_get_start_date' ) ? tribe_get_start_date( $event->ID, false, DATE_ATOM ) : null,
                'end_date'         => function_exists( 'tribe_get_end_date' ) ? tribe_get_end_date( $event->ID, false, DATE_ATOM ) : null,
                'dayof_available'  => (bool) $dayof_product,
                'dayof_price'      => $dayof_product ? (float) $dayof_product->get_price() : null,
                'ticket_price' => $ticket_price,
                'pot_value'    => (float) CCD_Raffle_Tickets::get_pot_value( $event->ID ),
                'tickets_sold' => (int) CCD_Raffle_Tickets::get_event_ticket_count( $event->ID ),
            );
        }

        return rest_ensure_response( $results );
    }

    /**
     * POST /ccd-raffle/v1/sales
     * Records one in-person Square sale as a real WooCommerce order, idempotent
     * on square_payment_id so a retried sync call after a flaky connection can
     * never create (or appear to create) a duplicate order.
     */
    public function create_sale( WP_REST_Request $request ) {
        $params = $request->get_json_params();
        if ( ! is_array( $params ) ) {
            $params = array();
        }

        $required = array( 'event_id', 'quantity', 'buyer_first_name', 'buyer_phone', 'square_payment_id' );
        foreach ( $required as $field ) {
            if ( empty( $params[ $field ] ) ) {
                return new WP_Error(
                    'missing_field',
                    sprintf( __( 'Missing required field: %s', 'ccd-raffle' ), $field ),
                    array( 'status' => 400 )
                );
            }
        }

        $event_id          = absint( $params['event_id'] );
        $quantity          = absint( $params['quantity'] );
        $first_name        = sanitize_text_field( $params['buyer_first_name'] );
        $last_name         = isset( $params['buyer_last_name'] ) ? sanitize_text_field( $params['buyer_last_name'] ) : '';
        $phone             = sanitize_text_field( $params['buyer_phone'] );
        $email             = ! empty( $params['buyer_email'] ) ? sanitize_email( $params['buyer_email'] ) : '';
        $square_payment_id = sanitize_text_field( $params['square_payment_id'] );
        $amount_charged    = isset( $params['amount_charged_cents'] ) ? absint( $params['amount_charged_cents'] ) : null;
        $device_id         = isset( $params['device_id'] ) ? sanitize_text_field( $params['device_id'] ) : '';
        // 'raffle' (default, backward compatible) or 'dayof_parking'.
        $sale_type         = isset( $params['sale_type'] ) ? sanitize_text_field( $params['sale_type'] ) : 'raffle';
        $is_dayof          = ( 'dayof_parking' === $sale_type );

        if ( $quantity < 1 ) {
            return new WP_Error( 'invalid_quantity', __( 'Quantity must be at least 1.', 'ccd-raffle' ), array( 'status' => 400 ) );
        }

        // Idempotency check FIRST -- a retried sync for an already-recorded payment
        // must short-circuit before any new order is even considered.
        $existing = $this->find_existing_sale( $square_payment_id );
        if ( $existing ) {
            return rest_ensure_response( $this->build_sale_response( $existing->order_id, $existing->event_id, true ) );
        }

        if ( $is_dayof ) {
            // Day-of parking/admission passes aren't gated by raffle sellability
            // (raffle-disabled or a winner already picked has nothing to do with
            // whether parking is still for sale) -- only that the event itself exists.
            $product = $this->get_dayof_product( $event_id );
            if ( ! $product ) {
                return new WP_Error( 'dayof_product_missing', __( 'No day-of parking product configured for this event.', 'ccd-raffle' ), array( 'status' => 500 ) );
            }
            $expected_cents = (int) round( (float) $product->get_price() * $quantity * 100 );
        } else {
            $sellable = CCD_Raffle::event_is_sellable( $event_id );
            if ( ! $sellable['sellable'] ) {
                return new WP_Error(
                    'event_not_sellable',
                    sprintf( __( 'This event is not currently sellable (%s).', 'ccd-raffle' ), $sellable['reason'] ),
                    array( 'status' => 409 )
                );
            }

            $product_id = get_option( 'ccd_raffle_base_product_id' );
            $product    = $product_id ? wc_get_product( $product_id ) : false;
            if ( ! $product ) {
                return new WP_Error( 'raffle_product_missing', __( 'Raffle product not configured.', 'ccd-raffle' ), array( 'status' => 500 ) );
            }

            // Sanity-check the charged amount against the current ticket price. A mismatch
            // (price changed between the app's cached event list and the sale) is logged on
            // the order, never used to block ticket creation -- the money's already taken.
            $ticket_price   = get_post_meta( $event_id, '_ccd_raffle_ticket_price', true );
            $ticket_price   = $ticket_price ? (float) $ticket_price : 5.0;
            $expected_cents = (int) round( $ticket_price * $quantity * 100 );
        }

        try {
            $order = wc_create_order();

            $item_id = $order->add_product( $product, $quantity );
            if ( ! $item_id ) {
                throw new Exception( 'Could not add product to order.' );
            }

            $item = $order->get_item( $item_id );
            // Different meta keys on purpose: CCD_Raffle_Tickets::generate_tickets()
            // only acts on items carrying _raffle_event_id, so a day-of parking item
            // (tagged _dayof_event_id instead) never triggers raffle ticket generation.
            $item->add_meta_data( $is_dayof ? '_dayof_event_id' : '_raffle_event_id', $event_id, true );
            $item->save();

            $order->set_billing_first_name( $first_name );
            $order->set_billing_last_name( $last_name );
            $order->set_billing_phone( $phone );
            $order->set_billing_email( $email ? $email : 'noemail+' . $square_payment_id . '@carsandcoffeedarien.com' );
            $order->set_created_via( 'ccd-raffle-app' );
            $order->set_payment_method( 'square_mobile_app' );
            $order->set_payment_method_title( __( 'Square (Tap to Pay - Mobile App)', 'ccd-raffle' ) );

            $note = sprintf(
                'In-person %s sale via CCD Raffle App. Square Payment ID: %s. Device: %s.',
                $is_dayof ? 'day-of parking' : 'raffle',
                $square_payment_id,
                $device_id ? $device_id : 'unknown'
            );
            if ( null !== $amount_charged && $amount_charged !== $expected_cents ) {
                $note .= sprintf(
                    ' NOTE: charged amount (%d cents) does not match expected (%d cents) -- price may have changed.',
                    $amount_charged,
                    $expected_cents
                );
            }
            $order->add_order_note( $note );

            $order->calculate_totals();
            // For raffle sales this synchronously fires CCD_Raffle_Tickets::generate_tickets()
            // (ticket numbers, pot update, buyer SMS). Day-of parking items are skipped by
            // that hook since they carry no _raffle_event_id meta.
            $order->update_status( 'completed', 'Payment captured via Square Tap to Pay mobile app. ' );

        } catch ( Exception $e ) {
            return new WP_Error( 'server_error', 'Failed to create order: ' . $e->getMessage(), array( 'status' => 500 ) );
        }

        global $wpdb;
        $inserted = $wpdb->insert(
            self::table_name(),
            array(
                'square_payment_id' => $square_payment_id,
                'order_id'          => $order->get_id(),
                'event_id'          => $event_id,
                'quantity'          => $quantity,
            ),
            array( '%s', '%d', '%d', '%d' )
        );

        if ( false === $inserted ) {
            // A near-simultaneous duplicate request beat us to the unique key.
            // Return ITS order rather than erroring -- the sale is recorded either way.
            $existing = $this->find_existing_sale( $square_payment_id );
            if ( $existing ) {
                return rest_ensure_response( $this->build_sale_response( $existing->order_id, $existing->event_id, true ) );
            }
        }

        return rest_ensure_response( $this->build_sale_response( $order->get_id(), $event_id, false ) );
    }

    /**
     * GET /ccd-raffle/v1/mobile-auth
     * Mints a short-lived (60 min), one-time-use Square "mobile authorization
     * code" server-side and hands it to the app -- the raw Square access
     * token (CCD_SQUARE_ACCESS_TOKEN) never leaves this server, per Square's
     * own guidance for the Mobile Payments SDK. The app calls
     * sdk.authorize(code, locationId) with the result of this endpoint,
     * never with CCD_SQUARE_ACCESS_TOKEN directly.
     */
    public function get_mobile_auth_code( WP_REST_Request $request ) {
        $token       = defined( 'CCD_SQUARE_ACCESS_TOKEN' ) ? CCD_SQUARE_ACCESS_TOKEN : '';
        $location_id = defined( 'CCD_SQUARE_LOCATION_ID' ) ? CCD_SQUARE_LOCATION_ID : '';
        $env         = defined( 'CCD_SQUARE_ENV' ) ? CCD_SQUARE_ENV : 'sandbox';

        if ( empty( $token ) || empty( $location_id ) ) {
            return new WP_Error(
                'square_not_configured',
                __( 'CCD_SQUARE_ACCESS_TOKEN / CCD_SQUARE_LOCATION_ID not set in wp-config.php.', 'ccd-raffle' ),
                array( 'status' => 500 )
            );
        }

        $base_url = ( 'production' === $env )
            ? 'https://connect.squareup.com'
            : 'https://connect.squareupsandbox.com';

        $response = wp_remote_post(
            $base_url . '/mobile/authorization-code',
            array(
                'headers' => array(
                    'Square-Version' => '2026-10-15',
                    'Authorization'  => 'Bearer ' . $token,
                    'Content-Type'   => 'application/json',
                ),
                'body'    => wp_json_encode( array( 'location_id' => $location_id ) ),
                'timeout' => 15,
            )
        );

        if ( is_wp_error( $response ) ) {
            return new WP_Error( 'server_error', 'Could not reach Square: ' . $response->get_error_message(), array( 'status' => 500 ) );
        }

        $code    = wp_remote_retrieve_response_code( $response );
        $body    = json_decode( wp_remote_retrieve_body( $response ), true );

        if ( 200 !== $code || empty( $body['authorization_code'] ) ) {
            return new WP_Error( 'server_error', 'Square did not return an authorization code.', array( 'status' => 500 ) );
        }

        return rest_ensure_response(
            array(
                'authorization_code' => $body['authorization_code'],
                'expires_at'         => $body['expires_at'],
                'location_id'        => $location_id,
            )
        );
    }

    /**
     * Look up a previously-recorded sale by Square payment ID.
     */
    private function find_existing_sale( $square_payment_id ) {
        global $wpdb;
        return $wpdb->get_row(
            $wpdb->prepare(
                'SELECT * FROM ' . self::table_name() . ' WHERE square_payment_id = %s',
                $square_payment_id
            )
        );
    }

    /**
     * Build the response shape shared by both the "freshly created" and
     * "idempotent replay" paths. Self-describing from the order's own line-item
     * meta (_dayof_event_id vs _raffle_event_id) rather than a passed-in flag,
     * so an idempotent replay reports the correct shape with no extra bookkeeping.
     */
    private function build_sale_response( $order_id, $event_id, $already_existed ) {
        $order = wc_get_order( $order_id );

        $ticket_numbers  = array();
        $dayof_item      = null;

        if ( $order ) {
            foreach ( $order->get_items() as $item ) {
                if ( (int) $item->get_meta( '_raffle_event_id' ) === (int) $event_id ) {
                    $numbers = $item->get_meta( '_raffle_ticket_numbers' );
                    if ( is_array( $numbers ) ) {
                        $ticket_numbers = array_merge( $ticket_numbers, $numbers );
                    }
                } elseif ( (int) $item->get_meta( '_dayof_event_id' ) === (int) $event_id ) {
                    $dayof_item = $item;
                }
            }
        }

        if ( $dayof_item ) {
            return array(
                'success'         => true,
                'already_existed' => $already_existed,
                'order_id'        => $order_id,
                'event_id'        => $event_id,
                'sale_type'       => 'dayof_parking',
                'quantity'        => $dayof_item->get_quantity(),
            );
        }

        return array(
            'success'                  => true,
            'already_existed'          => $already_existed,
            'order_id'                 => $order_id,
            'event_id'                 => $event_id,
            'sale_type'                => 'raffle',
            'quantity'                 => count( $ticket_numbers ),
            'ticket_numbers'           => $ticket_numbers,
            'ticket_numbers_formatted' => CCD_Raffle_Tickets::format_ticket_numbers( $ticket_numbers ),
            'pot_value'                => (float) CCD_Raffle_Tickets::get_pot_value( $event_id ),
        );
    }

    /**
     * The WooCommerce product configured for day-of parking/admission sales at
     * this event, via the _ccd_dayof_parking_product_id event meta -- or null if
     * none is configured (the default; day-of sales are opt-in per event).
     */
    private function get_dayof_product( $event_id ) {
        $product_id = get_post_meta( $event_id, '_ccd_dayof_parking_product_id', true );
        if ( ! $product_id ) {
            return null;
        }
        $product = wc_get_product( $product_id );
        return $product ? $product : null;
    }
}
