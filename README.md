# CCD Raffle App

A staff-operated mobile app (Flutter, iOS + Android) that lets a Cars & Coffee Darien ticket seller take Square Tap to Pay payments in person and have each sale land as a real WooCommerce order on carsandcoffeedarien.com — so the existing `ccd-raffle` plugin's ticket numbering, pot tracking, and winner SMS all fire automatically, the same as a web purchase.

See `C:\Users\richm\.claude\plans\parallel-plotting-moonbeam.md` for the full project plan (context, architecture, setup checklist, phased roadmap).

## Layout

- `docs/` — API contract and Eric's account-setup checklist, kept in sync with what's actually implemented/done.
- `wordpress-plugin-patch/` — the one new file (`class-ccd-raffle-app-api.php`) deployed onto the live `ccd-raffle` plugin on `bitnami@52.207.187.104`. This is the canonical source; the live plugin itself is not tracked here.
- `mobile/` — the Flutter app.

## Status

Phase 0 (WordPress REST endpoint) in progress. See `docs/setup-checklist.md` for what's done vs. pending on Eric's side (Square developer app, Apple entitlement, etc.).
