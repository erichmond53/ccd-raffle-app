# CCD Raffle App

Staff-operated Flutter app (iOS + Android) for in-person Square Tap to Pay raffle ticket sales at Cars & Coffee Darien events, syncing each sale to carsandcoffeedarien.com as a real WooCommerce order.

Full plan: `C:\Users\richm\.claude\plans\parallel-plotting-moonbeam.md`

## Key facts

- Live site: carsandcoffeedarien.com, WordPress/Bitnami on `bitnami@52.207.187.104` (SSH key already authorized, no password). No staging environment exists for this site — test against the live site using the dedicated test event only (see `docs/setup-checklist.md`).
- The existing `ccd-raffle` plugin (on the box at `/bitnami/wordpress/wp-content/plugins/ccd-raffle/`) already does ALL ticket numbering, pot calculation, and SMS notification via `CCD_Raffle_Tickets::generate_tickets()`, hooked on `woocommerce_order_status_processing`/`_completed`. This project's WordPress-side job is exactly one new file (`wordpress-plugin-patch/class-ccd-raffle-app-api.php`) that creates a correctly-shaped `WC_Order` — nothing in the existing plugin's ticket/SMS/pot logic should be modified, only reused.
- Raffle base product id is in option `ccd_raffle_base_product_id`. The critical order-item meta key the rest of the system depends on is `_raffle_event_id`.
- Auth between the app and WordPress is a static shared-secret header (`X-CCD-Raffle-App-Key`), NOT the WooCommerce REST consumer key/secret (that one's tied to the Printify integration and scoped to the whole store — don't reuse it).
- Idempotency is keyed on Square's `square_payment_id` — the Square charge happens once, client-side; the WordPress sync call must be safely retryable without ever creating a duplicate order.
- No Mac available locally as of project start — iOS builds are gated on Eric sorting that out himself; Android is the faster/unblocked path and should be built first.
