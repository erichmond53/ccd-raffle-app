# Eric's Setup Checklist

Living checklist — tick these off as they're done. Sequenced by lead time (longest-pole items first). Full context in the project plan: `C:\Users\richm\.claude\plans\parallel-plotting-moonbeam.md`.

## Start ASAP, no dependencies on anything else

- [x] Log into developer.squareup.com under the **business** Square account (not a stray personal login). Confirm whether a prior account exists there at all.
- [x] Create a new Application in the Square Developer Dashboard — "CCD Raffle Mobile App". Sandbox Application ID + access token obtained — see `docs/credentials.local.md` (not tracked in git).
- [x] ~~Request production Mobile Payments SDK / Tap to Pay capability~~ — correction (2026-11-15): there's no separate Square-side approval gate for this, unlike Apple's. The dashboard's "Mobile Payments SDK → Add signature" step needs a real iOS bundle ID + Apple Team ID (and/or Android package name + signing key SHA-256) — these don't exist until the Flutter app itself is scaffolded, so this is blocked on starting the app, not something to chase down early. Revisit once `mobile/` exists.
- [x] **Begin Apple Developer Program *organization* enrollment.** This is the single longest lead-time item in the whole project (business identity/D-U-N-S verification can take days to weeks). Start the same day as everything else, completely independent of any coding progress. Apple ID is eric@standonitmarketing.com
  - 2026-11-15: new Apple Account (eric@standonitmarketing.com) required live Apple Support assistance to create (self-serve creation failed twice with a vague "account cannot be created" error, resolved by support via Eric's tablet).
  - 2026-11-15: enrollment form submitted. **Enrollment ID: 8NYHS6XTLW.** Currently in Apple's "verify legal signing authority" step (confirming Eric can bind Stand On It Marketing LLC to agreements) — Apple will email next instructions. Nothing to do here but wait for that email.
- [ ] Sort out Mac / cloud-build access for Xcode. Blocks *any* iOS build — dev or release — regardless of how the Apple entitlement request is going. (You said this is "not a problem" — just flagging it stays on the critical path either way.)
  - 2026-11-15: decided on a **used MacBook (laptop)**, not a Mac mini — only ~$20 more and gets portability as a bonus. Spec target stays the same: M2 or later, 16GB RAM, 512GB storage minimum (RAM/storage aren't upgradeable after purchase on Apple Silicon). No monitor/keyboard logistics to solve now that it's a laptop.

## Done (WordPress side, built 2026-11-14)

- [x] `CCD_RAFFLE_APP_API_KEY` secret generated and added to `wp-config.php` on the box.
- [x] New REST endpoints (`GET /events`, `POST /sales`) built, deployed, and verified end-to-end against a throwaway test event — idempotency confirmed, ticket generation confirmed, pot update confirmed, buyer-confirmation SMS confirmed (via Twilio's own message log).

## After Apple org enrollment completes

- [ ] Request the Tap to Pay on iPhone **Development**-tier entitlement. Turnaround is unpublished — submit the moment enrollment clears.
- [ ] Register staff test iPhone UDIDs for development provisioning.

## Closer to season (once Android is further along)

- [ ] Request the **Distribution**-tier entitlement (needed for TestFlight; note: Ad Hoc distribution reportedly doesn't work even with this tier granted — plan around Development-tier local installs during build-out, then TestFlight *internal* distribution only). Internal TestFlight does **not** require public App Store review for a 1-2-phone internal tool like this.
- [ ] Obtain the **production** Square Application ID/Access Token (separate from the sandbox ones) once ready to test with real money.

## Android

- [ ] Nothing blocking — no equivalent approval gate exists. A sideloaded APK onto the staff phone(s) is enough. A Google Play Console account is only needed if you'd rather use Play's internal testing track instead of a raw sideload.

## Before going live at a real event

- [ ] One real sandbox Tap to Pay transaction on real Android hardware against the live WordPress endpoint.
- [ ] One real, small, production transaction (then refunded) before trusting the app with actual event traffic.
- [ ] Old Square terminal kept on hand as a fallback the first time the app's used live.
