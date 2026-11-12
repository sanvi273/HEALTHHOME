# HealthHome QA audit

Date: 2026-11-11

## Scope and baseline

The repository contains 65 Dart files under `frontend/lib` and 68 tracked backend files outside dependency and upload directories. The parent checkout already had its `backend` and `frontend` gitlinks advanced relative to the parent commit; those starting revisions were preserved.

This pass fixed the pharmacy delivery-partner assignment flow and made targeted startup, responsive, and analytics improvements. It did not manually exercise every role workflow or inspect every screen's constraints, and no live MongoDB, Firebase, Razorpay, or physical-device session was available. Treat this as a targeted QA pass, not complete production certification.

## Findings and changes

- The pharmacy selection sheet returned a dynamically typed partner map, while the result and assignment path expected a string map. It now returns an explicit `{name, phone}` string map.
- Assignment requests had no timeout or single-flight protection, and the bottom sheet closed before the request provided feedback. Added a 20-second API timeout, duplicate-submit guard, in-progress feedback, refresh after success, and clear failure feedback.
- Added a backend regression test that verifies an accepted order saves the selected partner name/phone, assignment flag, and timestamp.
- Startup waited two seconds before showing the app while fetching and printing unused push identifiers. Removed the unused token fetch, fixed wait, and verbose OneSignal logging; kept OneSignal initialization.
- Session restoration in both the root login gate and standalone splash screen imposed another fixed two-second wait. Removed the waits so local session state is read immediately, and removed patient phone/name debug output.
- The desktop responsive wrapper allowed content to grow to 1600px while the shared responsive utility capped desktop content at 1400px. Aligned the wrapper to the 1400px cap and added a widget smoke test for all 15 requested viewport widths.
- Admin analytics loaded full appointment, medicine order, and lab order documents although summaries use a subset of fields. Added projections and assertions for projected reads.

## Verification

- Backend tests: `node --test` — 10 passed, 0 failed, including the delivery-partner assignment regression test.
- Backend syntax: `node --check` — 65 JavaScript files checked, 0 failures.
- Flutter responsive widget test: passed at all 15 widths.
- Targeted Dart analysis of startup/responsive files and test — no issues found.
- Targeted analysis of pharmacy dashboard/API service reports existing warnings and infos; no errors in the changed assignment code. The full frontend analysis reported 195 diagnostics, including deprecated APIs, async context use, debug prints, and unused values.
- `git diff --check` passed for both submodules.
- Physical Android/iOS devices and live backend/payment workflows were not tested.

## Remaining audit work

- Review back navigation and responsive constraints manually on every patient, doctor, lab, pharmacy, and admin screen. This pass does not assert a complete screen-by-screen back-button count.
- Add pagination/projection to large catalogue and history endpoints where API contracts and client paging support permit. Broad reads remain in endpoints such as medicine/lab catalogues and lab orders.
- Exercise authentication and role permissions, booking/status transitions, OTP, report upload/view, and payment success/failure/COD through controlled test infrastructure.
- Resolve the broader Flutter analyzer backlog and run physical-device/browser checks.

## Changed files in this pass

- `QA_AUDIT.md`
- `frontend/lib/main.dart`
- `frontend/lib/screens/splash_screen.dart`
- `frontend/lib/responsive/responsive_wrapper.dart`
- `frontend/lib/pharmacy_dashboard.dart`
- `frontend/lib/services/api_service.dart`
- `frontend/test/responsive_wrapper_test.dart`
- `backend/controllers/adminAnalyticsController.js`
- `backend/controllers/orderController.js`
- `backend/test/admin-analytics.test.js`
- `backend/test/delivery-agent-assignment.test.js`

## Follow-up patient UI fixes

- Lab home collection no longer fetches, auto-selects, or displays saved addresses. The address controller starts empty and the patient enters the collection address directly. Added localized address hint and required-address feedback in English, Hindi, and Gujarati.
- The Doctors screen now always shows a top-left back button and uses `Navigator.maybePop` to return to the previous screen.
- The modified lab booking and doctor list files analyze with only four existing Flutter deprecation infos in the lab booking file. All three localization JSON files parse successfully. The responsive widget matrix test also passes; no live screen/API workflow test was run for these pages.

Additional files changed: `frontend/lib/screens/patient/book_lab_test_page.dart`, `frontend/lib/screens/patient/doctor_list_page.dart`, and `frontend/lib/l10n/{en,hi,gu}.json`.
