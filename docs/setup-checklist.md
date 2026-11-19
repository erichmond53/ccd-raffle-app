# Eric's Setup Checklist

Living checklist — tick these off as they're done. Sequenced by lead time (longest-pole items first). Full context in the project plan: `C:\Users\richm\.claude\plans\parallel-plotting-moonbeam.md`.

## Start ASAP, no dependencies on anything else

- [x] Log into developer.squareup.com under the **business** Square account (not a stray personal login). Confirm whether a prior account exists there at all.
- [x] Create a new Application in the Square Developer Dashboard — "CCD Raffle Mobile App". Sandbox Application ID + access token obtained — see `docs/credentials.local.md` (not tracked in git).
- [x] ~~Request production Mobile Payments SDK / Tap to Pay capability~~ — correction (2026-11-15): there's no separate Square-side approval gate for this, unlike Apple's. The dashboard's "Mobile Payments SDK → Add signature" step needs a real iOS bundle ID + Apple Team ID (and/or Android package name + signing key SHA-256) — these don't exist until the Flutter app itself is scaffolded, so this is blocked on starting the app, not something to chase down early. Revisit once `mobile/` exists.
- [x] **Begin Apple Developer Program *organization* enrollment.** This is the single longest lead-time item in the whole project (business identity/D-U-N-S verification can take days to weeks). Start the same day as everything else, completely independent of any coding progress. Apple ID is eric@standonitmarketing.com
  - 2026-11-15: new Apple Account (eric@standonitmarketing.com) required live Apple Support assistance to create (self-serve creation failed twice with a vague "account cannot be created" error, resolved by support via Eric's tablet).
  - 2026-11-15: enrollment form submitted. **Enrollment ID: 8NYHS6XTLW.** Currently in Apple's "verify legal signing authority" step (confirming Eric can bind Stand On It Marketing LLC to agreements) — Apple will email next instructions. Nothing to do here but wait for that email.
- [x] Sort out Mac / cloud-build access for Xcode. **Done 2026-11-18/19**: used MacBook Air (Apple Silicon, macOS 27.2.1) arrived, set up as a remote build machine reached over SSH — Xcode 27.2, Flutter 3.50.0, CocoaPods, Android command-line SDK tools, and Temurin JDK 21 all installed and verified working (see memory `eric-macbook-dev-setup-2026-11-19`). No separate Claude Code instance needed on the Mac itself.

## Done (WordPress side)

- [x] `CCD_RAFFLE_APP_API_KEY` secret generated and added to `wp-config.php` on the box (2026-11-14).
- [x] `GET /events`, `POST /sales` built, deployed, and verified end-to-end against a throwaway test event — idempotency confirmed, ticket generation confirmed, pot update confirmed, buyer-confirmation SMS confirmed (via Twilio's own message log).
- [x] `GET /mobile-auth` built and deployed (2026-11-19) — mints a short-lived, one-time Square mobile authorization code server-side so the raw `CCD_SQUARE_ACCESS_TOKEN` never ships inside the app. Verified live against production. Needs `CCD_SQUARE_ACCESS_TOKEN` / `CCD_SQUARE_LOCATION_ID` / `CCD_SQUARE_ENV` in `wp-config.php` (sandbox values added 2026-11-19; swap for production before any real-money use).

## Done (Flutter app — Phase 2, 2026-11-19)

- [x] Real `square_mobile_payments_sdk` wired in on both platforms (native init, permissions, Gradle/Xcode config). Real `flutter build apk` and `flutter build ios --simulator` both succeed; iOS build launches and runs on the Simulator without crashing.
- [ ] **Cannot take a real Tap to Pay charge yet** — blocked on the item below.

## After Apple org enrollment completes

- [ ] Request the Tap to Pay on iPhone **Development**-tier entitlement (`com.apple.developer.proximity-reader.payment.acceptance`). Turnaround is unpublished — submit the moment enrollment clears.
- [ ] Once granted: add the "Tap to Pay on iPhone" capability in Xcode (Runner target → Signing & Capabilities → "+ Capability") — this is a GUI-only step, Xcode generates the entitlements file itself.
- [ ] Register staff test iPhone UDIDs for development provisioning.

## Closer to season (once Android is further along)

- [ ] Request the **Distribution**-tier entitlement (needed for TestFlight; note: Ad Hoc distribution reportedly doesn't work even with this tier granted — plan around Development-tier local installs during build-out, then TestFlight *internal* distribution only). Internal TestFlight does **not** require public App Store review for a 1-2-phone internal tool like this.
- [ ] Obtain the **production** Square Application ID/Access Token/Location ID (separate from the sandbox ones) once ready to test with real money — update both `wp-config.php` (`CCD_SQUARE_*`) and the hardcoded sandbox Application ID in `AppDelegate.swift` / `MainApplication.kt`.

## Android

- [x] Toolchain set up on the Mac (no Android Studio needed, just the command-line SDK tools) — but this work can equally happen on Eric's PC instead, since Android builds don't require macOS.
- [ ] No sideload/real-device test done yet. Nothing blocking — no equivalent approval gate exists. A Google Play Console account is only needed if you'd rather use Play's internal testing track instead of a raw sideload.

## Before going live at a real event

- [ ] One real sandbox Tap to Pay transaction on real Android hardware against the live WordPress endpoint.
- [ ] One real, small, production transaction (then refunded) before trusting the app with actual event traffic.
- [ ] Old Square terminal kept on hand as a fallback the first time the app's used live.
