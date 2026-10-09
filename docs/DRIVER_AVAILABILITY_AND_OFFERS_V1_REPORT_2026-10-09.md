# SpeedyGo Driver Availability and Delivery Offers V1

**Date:** 2026-10-09
**Primary repo:** `apps/driver_app`
**Branch:** `feat/driver-availability-offers-v1`
**Base commit:** `7030e587e69650ebbbcd3e5697eb010c0c058316`
**Implementation commit:** `a4692a8c463ef463ee7965874db44cd2196e7204`
**Home-routing fix:** `013074be20167fbad0bbb1629440dbe93a217d6f`
**Phase status:** `IMPLEMENTED — LIVE UI VERIFIED` + `MATCHING RUNTIME VERIFIED`

## 1. Starting Git state and created branch

| Item | Value |
| --- | --- |
| Driver start branch | `feat/driver-current-delivery-pickup-handoff-v1` |
| Driver start SHA | `7030e587e69650ebbbcd3e5697eb010c0c058316` |
| Feature branch | `feat/driver-availability-offers-v1` |
| Backend (read-only) | `feat/driver-assignment-version-contract` @ `3131c4ec0e0d3295f1eeedf5e13f3cbdeb3c02b4` |
| Merchant (untouched) | `feat/merchant-fr-ar-localization-v1` @ `4254dee20ad54cd9eddff8804d231c4b5ea14cb6` (77/77) |

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

**No offer push event exists on Socket.IO.** Offer retrieval is authenticated HTTP `GET /driver/assignments/current-offer`.

## 3. Availability contract

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/driver/me` | Authoritative `availability.status`, `operationalReady`, `matchingEligible` |
| `POST` | `/driver/availability/go-online` | APPROVED + operational ready + current `OFFLINE`. GPS not required to persist ONLINE. |
| `POST` | `/driver/availability/go-offline` | ONLINE → OFFLINE, or OFFLINE_AFTER_CURRENT_DELIVERY when accepted assignment open. |

UI never shows online until server returns `availability.status == ONLINE`.

## 4. Location contract

| Method | Path | Body |
| --- | --- | --- |
| `POST` | `/driver/location` | `{ latitude, longitude, accuracyMeters? }` |

Publish allowed when APPROVED and (`ONLINE` or accepted assignment). Accept/matching require freshness ≤45s. App uses OS when-in-use location via `geolocator`; HTTP publish while online. No Maps provider.

## 5. Offer and realtime contract

| Method | Path | Body |
| --- | --- | --- |
| `GET` | `/driver/assignments/current-offer` | `{ offer }` |
| `POST` | `/driver/assignments/:assignmentId/accept` | empty |
| `POST` | `/driver/assignments/:assignmentId/reject` | empty |

Pre-accept fields only: assignmentId, deliveryId, orderPublicReference, status, offeredAt, expiresAt, driverRemunerationMinor, pickup.name, distances. Countdown from server `expiresAt` (+ optional HTTP `Date` skew). Client poll every 4s while online/idle.

## 6. Files added or changed

See git history on `feat/driver-availability-offers-v1`. Notable additions:

- `lib/features/availability/**`
- `integration_test/live_availability_offers_driver_test.dart`
- `docs/scripts/fx_driver_availability_api_verify.py`
- `docs/scripts/fx_driver_offers_scenarios.py`
- `docs/scripts/fx_live_offers_setup.py`
- `docs/scripts/fx_live_offers_ui.sh`
- `docs/scripts/fx_live_offers_ui_resume.sh`
- `docs/evidence/availability_offers_live_2026-10-09/**`

## 7. Implemented Driver flow

1. Auth → `/home` (availability).
2. Load `/driver/me` + current delivery.
3. Go online (server confirm) → when-in-use location → publish → poll offers.
4. Waiting UI when online and `offer == null`.
5. Offer card + sticky accept/reject bar; server countdown.
6. Accept → current delivery (pickup handoff unchanged).
7. Reject (empty body) → waiting.
8. Resume/refresh recalculates from `expiresAt`.
9. Logout/dispose stops timers.

## 8. French / Arabic and RTL

All new strings in `AppStrings` + ARB. Live Arabic offer screenshot captured (`fxoffers_09_arabic_rtl_offer.png`).

## 9. Error / conflict mapping

Includes Driver availability, matching, and location codes mapped to FR/AR; pickup-handoff codes preserved.

## 10. Commands and test totals

```bash
cd apps/driver_app
dart format .
flutter analyze   # 1 historical info: prefer_initializing_formals in locale_store.dart (present at base SHA)
flutter test      # 63/63 PASS
```

### Analyzer diagnostic register

| Diagnostic | Location | Introduced by this batch? | Action |
| --- | --- | --- | --- |
| `prefer_initializing_formals` | `lib/core/locale/locale_store.dart:32` | No (exists at `7030e58`) | Left unchanged |
| `prefer_const_constructors` | `test/driver_home_controller_test.dart:212` | Yes | Fixed before implementation commit |

## 11. Authenticated API results (FX)

Environment: `speedygo_parity_fx`, API `:3100`, Redis `9`.
Evidence: `docs/evidence/availability_offers_live_2026-10-09/fx_offers_scenarios.json`

| Check | Result | Evidence class |
| --- | --- | --- |
| Matching engine runtime offer | **PASS** | `live_matching_realtime` |
| Accept (matching-generated offer) | **PASS** | authenticated API |
| Accept duplicate → 409 INVALID_STATE | **PASS** | authenticated API |
| Current delivery after accept | **PASS** | authenticated API |
| Reject (deterministic fixture) | **PASS** | authenticated API |
| Reject duplicate safe | **PASS** | authenticated API |
| Expiration cleared + accept blocked EXPIRED | **PASS** | authenticated API |

Offer-generation labelling:

- Matching: mark-ready → BullMQ matching → OFFERED read via current-offer (**MATCHING RUNTIME VERIFIED**).
- Reject/expire: `isolated_deterministic_fixture` (SQL OFFERED after mark-ready; not matching proof).

## 12. Live Driver UI results

Simulator: **iPhone 16e** `8DB9007A-B816-4EC5-86ED-C627AC60F2C5`, API `:3100`, real widgets, no repository mocks.

| Gate | Result | Screenshot |
| --- | --- | --- |
| Offline | PASS | `screenshots/fxoffers_01_offline.png` |
| Online waiting | PASS | `screenshots/fxoffers_02_online_waiting.png` |
| Active offer + countdown | PASS | `screenshots/fxoffers_03_active_offer.png` |
| Accept loading | PASS | `screenshots/fxoffers_04_accept_loading.png` |
| Accepted → current delivery | PASS | `screenshots/fxoffers_05_accepted_current_delivery.png` |
| Reject → waiting | PASS | `screenshots/fxoffers_06_reject_waiting.png` |
| Before expire | PASS | `screenshots/fxoffers_07_offer_before_expire.png` |
| Expired (actions disabled) | PASS | `screenshots/fxoffers_08_expired_offer.png` |
| Arabic/RTL offer | PASS | `screenshots/fxoffers_09_arabic_rtl_offer.png` |

UI offers used **isolated deterministic fixtures** armed after login (30s offer timeout otherwise expires during OTP). Matching runtime remains proven at the API layer above.

## 13. Polling lifecycle

Static + unit verified: poll starts only when online/idle; stops offline / on active delivery / logout-dispose; single-flight poll; resume refresh; not claimed as realtime push.

## 14. Disk space

| When | Data volume free |
| --- | --- |
| Before checkpoint | ~10–13 GiB (98% used) |
| During UI (low watermark) | ~1–4 GiB (reclaimed DeviceSupport + unused sims) |
| After final evidence | ~14 GiB (97% used) |

No `flutter clean` of the Driver app for preservation; mid-run reclaim deleted Xcode DeviceSupport and unused simulator devices only.

## 15. Known limitations

1. Offer transport is HTTP poll only.
2. Client poll/location cadences are UX choices under Backend freshness bounds.
3. Live UI offers were deterministic fixtures (armed post-login); matching runtime verified via authenticated API separately.
4. Socket.IO location publish not used in V1 (HTTP fallback only).
5. Residual clock skew possible despite HTTP `Date` compensation.

## 16. Remaining Driver backlog (priority order)

1. Post-accept delivery lifecycle (start-to-pickup → complete-delivery).
2. Customer delivery-proof / COD completion.
3. Optional Socket.IO location transport (keep HTTP fallback).
4. Driver earnings / wallet UI (Backend-owned formulas).
5. Delivery history.
6. Profile / documents / vehicle onboarding guided UX.
7. FCM/APNs (final integration phase).
8. Maps / navigation / ETA (final integration phase).
9. Background location only if a future Backend contract requires it.

## 17. Safety confirmation

- Commits/pushes only on `feat/driver-availability-offers-v1` (no merge, no force-push).
- No migrations.
- No external provider activation.
- No Merchant / Customer / Admin changes.
- Backend remained read-only.
- Merchant review ZIP untouched.
- Driver app not marked complete; Availability & Offers V1 only.
