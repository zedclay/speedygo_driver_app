# SpeedyGo Driver Availability and Delivery Offers V1

**Date:** 2026-10-09  
**Primary repo:** `apps/driver_app`  
**Branch:** `feat/driver-availability-offers-v1`  
**Base commit:** `7030e587e69650ebbbcd3e5697eb010c0c058316` (`feat/driver-current-delivery-pickup-handoff-v1`)  
**HEAD (uncommitted work on same SHA):** `7030e587e69650ebbbcd3e5697eb010c0c058316`

## 1. Starting Git state and created branch

| Item | Value |
| --- | --- |
| Driver start branch | `feat/driver-current-delivery-pickup-handoff-v1` |
| Driver start SHA | `7030e587e69650ebbbcd3e5697eb010c0c058316` |
| Created branch | `feat/driver-availability-offers-v1` (from pickup-handoff tip) |
| Backend (read-only) | `feat/driver-assignment-version-contract` @ `3131c4ec0e0d3295f1eeedf5e13f3cbdeb3c02b4` |
| Merchant (untouched) | `feat/merchant-fr-ar-localization-v1` @ `4254dee20ad54cd9eddff8804d231c4b5ea14cb6` |
| Commit / push | **None** (explicitly withheld) |

Worktree was clean at the pickup SHA before the feature branch was created. Implementation remains local and uncommitted.

## 2. Backend contract inventory (source-backed)

| Area | Source paths |
| --- | --- |
| Driver me + availability HTTP | `apps/backend/src/modules/drivers/presentation/http/driver.controller.ts` |
| Driver me / availability DTOs | `apps/backend/src/modules/drivers/presentation/http/dto/driver-response.dto.ts` |
| Availability service rules | `apps/backend/src/modules/drivers/application/driver.service.ts` |
| Availability policy | `apps/backend/src/modules/drivers/domain/driver.policy.ts` |
| Driver error codes | `apps/backend/src/modules/drivers/domain/driver.errors.ts` |
| Location HTTP fallback | `apps/backend/src/modules/tracking/presentation/http/driver-location.controller.ts` |
| Location DTO | `apps/backend/src/modules/tracking/presentation/http/dto/tracking-response.dto.ts` |
| Location publish rules | `apps/backend/src/modules/tracking/application/tracking.service.ts`, `tracking/domain/tracking.policy.ts` |
| Socket.IO location event only | `apps/backend/src/modules/tracking/domain/tracking.events.ts` (`driver:location:update`) |
| Offer / accept / reject HTTP | `apps/backend/src/modules/matching/presentation/http/driver-assignment.controller.ts` |
| Offer DTOs | `apps/backend/src/modules/matching/presentation/http/dto/assignment-response.dto.ts` |
| Matching accept location freshness | `apps/backend/src/modules/matching/application/matching.service.ts` (`locationMaxAgeMs` default 45_000) |
| Offer expiry derivation | `apps/backend/src/modules/matching/domain/matching.policy.ts` (`offerExpiresAt`) |
| Offer timeout config | `apps/backend/src/config/configuration.ts` (`MATCHING_OFFER_TIMEOUT_MS`, default 30_000) |
| Matching errors | `apps/backend/src/modules/matching/domain/matching.errors.ts` |
| Current delivery (post-accept) | `apps/backend/src/modules/delivery/presentation/http/driver-delivery.controller.ts` |

**No offer push event exists on Socket.IO.** Realtime socket traffic for Drivers is location publish (`driver:location:update`). Offer retrieval is authenticated HTTP `GET /driver/assignments/current-offer`.

## 3. Availability contract

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/driver/me` | Authoritative `availability.status`, `operationalReady`, `matchingEligible` |
| `POST` | `/driver/availability/go-online` | Requires APPROVED + operational ready + current `OFFLINE`. GPS **not** required to persist `ONLINE`. Returns `DriverMeResponseDto`. |
| `POST` | `/driver/availability/go-offline` | `ONLINE` → `OFFLINE`, or `OFFLINE_AFTER_CURRENT_DELIVERY` when an accepted assignment is open. |

Statuses used by UI: `OFFLINE`, `ONLINE`, `OFFLINE_AFTER_CURRENT_DELIVERY`, `SUSPENDED`.

Client rule: never show online until `go-online` returns `availability.status == ONLINE`.

## 4. Location contract

| Method | Path | Body |
| --- | --- | --- |
| `POST` | `/driver/location` | `{ latitude, longitude, accuracyMeters? }` |

Publish allowed when APPROVED and (`ONLINE` **or** has accepted assignment). Same store as Socket.IO. Does not change availability. Accept/matching require a fresh store point (≤ `matching.locationMaxAgeMs`, default **45s**).

Driver app uses OS location via `geolocator` (when-in-use only). HTTP publish every **20s** while online (client cadence under the 45s freshness bound). No Google Maps / Places / background location.

## 5. Offer and realtime contract

| Method | Path | Body |
| --- | --- | --- |
| `GET` | `/driver/assignments/current-offer` | — → `{ offer: AssignmentOffer \| null }` |
| `POST` | `/driver/assignments/:assignmentId/accept` | empty |
| `POST` | `/driver/assignments/:assignmentId/reject` | empty (no reason field) |

Pre-accept offer fields (privacy boundary): `assignmentId`, `deliveryId`, `orderPublicReference`, `status`, `offeredAt`, `expiresAt`, `driverRemunerationMinor`, `pickup.name`, `pickupDistanceMeters`, `deliveryDistanceMeters?`. No customer phone, merchant phone, or exact dropoff address.

Countdown uses server `expiresAt` (+ optional HTTP `Date` skew). Client poll of `current-offer` every **4s** while online and idle (not a new endpoint).

After accept: clear offer → refresh `GET /driver/deliveries/current` → navigate to existing pickup handoff screen.

## 6. Files added or changed

### Added

- `lib/features/availability/data/driver_me_models.dart`
- `lib/features/availability/data/offer_models.dart`
- `lib/features/availability/data/availability_api.dart`
- `lib/features/availability/data/device_location.dart`
- `lib/features/availability/application/offer_countdown.dart`
- `lib/features/availability/application/driver_home_controller.dart`
- `lib/features/availability/presentation/driver_home_screen.dart`
- `test/offer_countdown_test.dart`
- `test/driver_me_models_test.dart`
- `test/driver_home_controller_test.dart`
- `test/driver_home_screen_test.dart`
- `docs/scripts/fx_driver_availability_api_verify.py`
- `docs/evidence/fx_availability_2026-10-09/*`
- `docs/DRIVER_AVAILABILITY_AND_OFFERS_V1_REPORT_2026-10-09.md` (this file)

### Changed

- `lib/core/constants/app_constants.dart` — endpoints + `/home` route
- `lib/core/constants/app_strings.dart` — FR/AR availability/offer/location/errors
- `lib/l10n/app_fr.arb`, `lib/l10n/app_ar.arb` (+ generated localizations)
- `lib/app/router/app_router.dart` — authed home → availability
- `lib/features/delivery/presentation/current_delivery_screen.dart` — back to home
- `pubspec.yaml` / `pubspec.lock` — `geolocator`
- `ios/Runner/Info.plist` — `NSLocationWhenInUseUsageDescription`
- `android/app/src/main/AndroidManifest.xml` — coarse/fine location + internet

## 7. Implemented Driver flow

1. Auth → `/home` (availability).
2. Load `/driver/me` + current delivery.
3. Go online (server confirm) → request when-in-use location → publish → poll offers.
4. Waiting UI when online and `offer == null`.
5. Offer card with authorized fields + server countdown.
6. Accept (publish fresh location first) → current delivery screen (pickup handoff unchanged).
7. Reject (empty body) → clear offer → continue waiting.
8. Resume / refresh recalculates countdown from `expiresAt` and reloads authoritative state.
9. Logout / dispose stops timers and clears state.

## 8. French / Arabic and RTL

All new user-visible strings exist in `AppStrings` and matching ARB keys (FR + AR). Arabic home rendering uses RTL `Directionality`. Operational identifiers (order ref, countdown, distances, remuneration) use LTR / tabular figures where needed. Widget tests cover FR and AR availability labels.

## 9. Error / conflict mapping

Mapped via `AppStrings.errorForCode` including:

- `DRIVER_NOT_APPROVED`, `DRIVER_NOT_OPERATIONAL`, `DRIVER_ONBOARDING_INCOMPLETE`
- `DRIVER_AVAILABILITY_INVALID_TRANSITION`, `DRIVER_PROFILE_NOT_FOUND`
- `DRIVER_ASSIGNMENT_EXPIRED`, `DRIVER_ASSIGNMENT_INVALID_STATE`, `DRIVER_ASSIGNMENT_NOT_FOUND`
- `DELIVERY_ALREADY_ASSIGNED`, `DELIVERY_NOT_SEARCHING_DRIVER`, `DRIVER_ALREADY_ASSIGNED`
- `DRIVER_LOCATION_REQUIRED`, `DRIVER_LOCATION_STALE`, `DRIVER_LOCATION_NOT_ALLOWED`
- `DRIVER_NOT_MATCHING_ELIGIBLE`
- Existing pickup-handoff codes unchanged

Location OS failures map to dedicated FR/AR guidance (services disabled, denied, denied forever, timeout, unavailable).

## 10. Commands and test totals

```bash
cd apps/driver_app
dart format .
flutter gen-l10n
flutter analyze   # no errors; pre-existing/info lints only
flutter test      # 63/63 passed
```

| Suite focus | Result |
| --- | --- |
| Offer countdown unit | PASS |
| Driver me / offer models | PASS |
| Availability controller (online/offline, location, accept/reject, expiry, logout) | PASS |
| Home widget FR/AR/RTL, countdown, layout 390×844 @ 1.35, navigation | PASS |
| Existing pickup-handoff + localization suites | PASS |
| **Total** | **63 passed** |

## 11. Authenticated API results (FX)

Environment: `speedygo_parity_fx`, API `:3100`, Redis index `9`.

Script: `docs/scripts/fx_driver_availability_api_verify.py`  
Evidence: `docs/evidence/fx_availability_2026-10-09/fx_availability_api_verify.json`

| Check | Result |
| --- | --- |
| API reachable | PASS |
| Driver OTP login | PASS |
| `GET /driver/me` | PASS |
| `POST .../go-online` → ONLINE + matchingEligible | PASS |
| `POST /driver/location` | PASS |
| `GET .../current-offer` | PASS (`offer=null`) |
| Accept / reject / expiration against live offer | **NOT VERIFIED** (no OFFERED assignment present; mutating matching fixture deferred) |
| `GET /driver/deliveries/current` | PASS |
| `POST .../go-offline` | PASS |

Scoped FX fixture note: Driver A documents were inserted via `fx_sql.sh` (IDENTITY + DRIVING_LICENSE) so `operationalReady` matched Backend policy. No migrations, no `FLUSHDB`, no Merchant/Customer app changes.

## 12. Evidence classification

| Claim | Classification |
| --- | --- |
| Backend contracts | static inspection |
| Availability / offer / countdown / accept-reject client logic | unit / widget |
| FR / AR / RTL home UI | mocked UI (widget) |
| Pickup handoff still green | unit / widget (existing) |
| FX go-online / location / current-offer read | authenticated API |
| Live Driver UI on device/emulator | **NOT VERIFIED** |
| Live matching offer delivery + accept/reject + expiration E2E | **NOT VERIFIED** |
| Socket.IO offer push | N/A (not provided by Backend) |
| Google Maps / FCM / SMS production | deferred (not activated) |

## 13. Disk space

| When | Available on data volume |
| --- | --- |
| Before implementation | ~10 GiB free (98% used) |
| After implementation + tests | ~10 GiB free (98% used) |

No `flutter clean` was run.

## 14. Known limitations

1. Offer transport is HTTP poll only; no Backend offer socket event.
2. Client poll (4s) and location publish (20s) cadences are UX choices under Backend freshness/timeout contracts — not Backend-prescribed intervals.
3. Live accept/reject/expiration against a real matching offer was not exercised in FX during this batch.
4. Live Driver UI on a physical device/emulator was not run.
5. Socket.IO location publish is supported by Backend but V1 uses the documented HTTP fallback only.
6. Clock skew compensation uses HTTP `Date` when present; residual skew remains possible.

## 15. Remaining Driver backlog (priority order)

1. **Live matching E2E** — seed SEARCHING_DRIVER → offer → accept/reject/expire on FX; wire evidence to UI.
2. **Post-accept delivery lifecycle** — start-to-pickup, arrive-pickup, start-delivery, arrive-customer, complete-delivery (contract-first).
3. **Customer delivery-proof / COD completion** — when Backend contracts are product-ready.
4. **Socket.IO location transport** (optional optimization) — keep HTTP fallback.
5. **Driver earnings / wallet** — deferred financial UI; Backend-owned formulas only.
6. **Delivery history** — list/detail from existing history controller.
7. **Profile / documents / vehicle onboarding UI** — currently API-only; blocked online paths need guided UX.
8. **Push notifications (FCM/APNs)** — final integration phase only.
9. **Maps / navigation / ETA** — final integration phase only (external providers deferred).
10. **Background location** — only if a future Backend contract requires it.

## 16. Safety confirmation

- No git commit or push.
- No migrations applied.
- No external provider activation (Maps, SMS production, FCM/APNs, payments, email).
- No Merchant, Customer, or Admin code changes.
- Backend remained read-only (no Backend source edits).
- Merchant review ZIP untouched.
- Driver app not marked complete; this is Availability & Offers V1 only.
