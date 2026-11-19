# CCD Raffle App — WordPress API Contract

Base URL: `https://carsandcoffeedarien.com/wp-json/ccd-raffle/v1`

Status: **Live in production** as of 2026-11-14. Verified end-to-end (idempotency, ticket generation, pot update, buyer SMS) against a throwaway test event, which has since been deleted.

## Auth

Every request must include:

```
X-CCD-Raffle-App-Key: <the secret>
```

Checked via `hash_equals()` against the `CCD_RAFFLE_APP_API_KEY` constant in `wp-config.php` on the box (`bitnami@52.207.187.104`). Missing/wrong key → `401 { "code": "invalid_api_key" }`.

This is a dedicated secret, not the WooCommerce REST consumer key/secret — don't reuse WooCommerce keys for this app, and don't reuse this key for anything else.

## `GET /events`

Returns upcoming, raffle-enabled, still-sellable events — the same "sellable" check (`CCD_Raffle::event_is_sellable()`) the web purchase page uses, so this list can never show an event the web page would refuse to sell for (or vice versa).

**Response:**
```json
[
  {
    "event_id": 7220,
    "title": "Example Event",
    "start_date": "2026-11-15T08:00:00-05:00",
    "end_date": "2026-11-15T23:00:00-05:00",
    "ticket_price": 5,
    "pot_value": 0,
    "tickets_sold": 0
  }
]
```

An event disappears from this list the moment it's no longer sellable (raffle disabled, event ended, or a winner's been picked) — the app should refresh this list each time it's opened, not cache it across sessions.

## `POST /sales`

Called once per completed Square charge, after the SDK confirms the payment succeeded client-side.

**Request:**
```json
{
  "event_id": 7220,
  "quantity": 5,
  "buyer_first_name": "Jane",
  "buyer_last_name": "Doe",
  "buyer_phone": "+12035551234",
  "buyer_email": "",
  "square_payment_id": "sq0idp-XXXXXXXXXXXXXXXXXXXXXX",
  "amount_charged_cents": 2500,
  "device_id": "staff-phone-1"
}
```

Required: `event_id`, `quantity`, `buyer_first_name`, `buyer_phone`, `square_payment_id`. `buyer_last_name`, `buyer_email`, `amount_charged_cents`, `device_id` are optional (a missing email gets a `noemail+<payment_id>@carsandcoffeedarien.com` placeholder so WooCommerce's billing-email field is never blank).

**Response (both a fresh sale and an idempotent replay return this same shape):**
```json
{
  "success": true,
  "already_existed": false,
  "order_id": 7221,
  "event_id": 7220,
  "quantity": 5,
  "ticket_numbers": [1, 2, 3, 4, 5],
  "ticket_numbers_formatted": "0001-0005",
  "pot_value": 25
}
```

**The critical guarantee:** calling this twice with the *same* `square_payment_id` (e.g. a client retry after a flaky connection) never creates a second order — the second call returns `already_existed: true` with the identical `order_id`/ticket numbers from the first call. Verified directly against the live idempotency table (`wp_ccd_raffle_app_sales`, unique on `square_payment_id`).

**Error responses:**

| HTTP | `code` | Meaning | App behavior |
|---|---|---|---|
| 401 | `invalid_api_key` | bad/missing header | permanent — don't retry, flag as a config problem |
| 400 | `missing_field` / `invalid_quantity` | bad request shape | permanent — this is a client bug, don't retry |
| 409 | `event_not_sellable` | event ended / winner picked / raffle disabled since the app last fetched `/events` | permanent — surface to staff, don't retry (money's already taken, needs human reconciliation) |
| 500 | `raffle_product_missing` / `server_error` | WordPress-side problem | **transient — keep retrying** with backoff |

This 4xx-vs-5xx split is exactly what the app's local sync queue should branch on: 5xx → stays `pending`, retried; 4xx → `failed_permanent`, surfaced in the History screen for manual reconciliation.

**What happens server-side on success:** a real WooCommerce order is created (product = the existing raffle base product, line-item meta `_raffle_event_id` set, billing fields set from the request, status set straight to `completed`), which synchronously fires the *existing, unmodified* `CCD_Raffle_Tickets::generate_tickets()` hook — ticket numbers assigned, pot updated, and the buyer confirmation SMS sent, exactly as for a web purchase. Nothing in the ticket/SMS/pot system was changed to make this work.

## Implementation notes for whoever builds the Flutter client

- If `amount_charged_cents` doesn't match `ticket_price × quantity × 100`, the sale still goes through — a mismatch is just logged as an order note (price may have changed between the app's cached `/events` list and the sale). Don't block on this client-side either.
- `square_payment_id` should be the actual Square Mobile Payments SDK payment ID, not a client-generated UUID — it's the one thing that's genuinely unique per real charge and lets the server dedupe correctly even across app reinstalls/local-data loss.
