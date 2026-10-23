# Driver Current Delivery + Pickup Handoff V1 — Implementation Report

**Date:** 2026-10-04  
**App:** `apps/driver_app`  
**Branch:** `feat/driver-current-delivery-pickup-handoff-v1`  
**Starting SHA:** `0de24a01df66c12f5f58631045bd4270c66c36d0` (`main`)  
**Backend contract snapshot:** `apps/backend` branch `snapshot/2026-10-04-current-workspace` @ `d188a216066679e972ff3b11fda0bd6e38943f71` (+ minimal local `assignmentVersion` expose; uncommitted)

**Git actions this batch:** none (no commit, push, merge, or rewrite).

---

## 1. Summary

Implemented a production-oriented Driver vertical slice:

1. Minimal OTP auth + secure session restore.
2. Load current delivery from `GET /driver/deliveries/current`.
3. State-driven current-delivery screen (French LTR).
4. Merchant pickup-code entry + `POST …/confirm-pickup`.
5. Legacy empty-body confirmation when no handoff row exists.
6. Error mapping, double-submit guard, in-memory code hygiene, post-success refresh of authoritative status.

Merchant parity row 23 is **not** closed (requires a separate cross-app verification task).

---

## 2. Files changed

### Driver (`apps/driver_app`) — uncommitted on feature branch

| Path | Change |
| --- | --- |
| `pubspec.yaml` / `pubspec.lock` | Added `flutter_secure_storage`, Riverpod stack already present |
| `lib/core/constants/app_constants.dart` | Routes + API paths |
| `lib/core/constants/app_strings.dart` | **New** — French UI / error strings |
| `lib/core/errors/app_exception.dart` | Network / API / refresh exceptions |
| `lib/core/network/api_client.dart` | Dio + auth interceptor |
| `lib/core/network/api_config.dart` | **New** |
| `lib/core/network/api_error_parser.dart` | **New** |
| `lib/core/network/token_refresher.dart` | **New** |
| `lib/core/storage/session_store.dart` | **New** — secure + in-memory stores |
| `lib/app/router/app_router.dart` | Auth-gated GoRouter |
| `lib/app/theme/app_theme.dart` | M3 light theme |
| `lib/app/shell/app_shell.dart` | Shell trim |
| `lib/app/providers/app_providers.dart` | App name provider |
| `lib/features/auth/**` | **New** — session, OTP phone/OTP screens, splash |
| `lib/features/delivery/**` | **New** — models, API, controller, screen, code input |
| `test/delivery_models_test.dart` | **New** |
| `test/current_delivery_controller_test.dart` | **New** |
| `test/current_delivery_screen_test.dart` | **New** |
| `test/widget_test.dart` | Bootstrap → phone screen |
| `docs/DRIVER_CURRENT_DELIVERY_PICKUP_HANDOFF_V1_REPORT.md` | **New** (this file) |

### Backend (`apps/backend`) — uncommitted local contract fix only

| Path | Change |
| --- | --- |
| `src/modules/delivery/application/driver-delivery.service.ts` | Expose `assignmentVersion` on `DriverCurrentDeliveryView` / `getCurrent` / `completeDelivery` return |
| `src/modules/delivery/presentation/http/dto/driver-delivery-response.dto.ts` | Document `assignmentVersion` on response DTO |

**Rationale:** confirm-pickup with a PENDING handoff requires `pickupCode` + `assignmentId` + `assignmentVersion`. The version already existed on `DriverAssignment` and in handoff verification; it was missing from the Driver current-delivery response, so the client could not supply it without inventing state. Minimal expose only — no behavior change to confirmation logic.

### Unchanged apps

Customer, Merchant, Admin — not modified.

---

## 3. Contracts used

Inspected / followed:

- `docs/architecture/MERCHANT_ASSIGNED_DRIVER_AND_PICKUP_HANDOFF.md`
- `docs/architecture/DRIVER_DELIVERY_WORKFLOW.md`
- Backend: `driver-delivery.controller.ts`, `driver-delivery.service.ts`, `confirm-pickup.dto.ts`, `pickup-handoff.service.ts`
- `03_DRIVER_CONSISTENCY_LOCK.md` — **not present in this workspace tree**; Android-first `390×844`, M3, French LTR, 48px targets applied from task constraints + handoff references.

### HTTP

| Method | Path | Auth |
| --- | --- | --- |
| `POST` | `/api/v1/auth/otp/request` | public |
| `POST` | `/api/v1/auth/otp/verify` | public |
| `POST` | `/api/v1/auth/refresh` | public (refresh token body) |
| `POST` | `/api/v1/auth/logout` | Bearer |
| `GET` | `/api/v1/auth/me` | Bearer |
| `GET` | `/api/v1/driver/deliveries/current` | Bearer → `{ delivery: View \| null }` |
| `POST` | `/api/v1/driver/deliveries/current/confirm-pickup` | Bearer → `View` (unwrapped) |

### Confirm body (all optional at DTO layer)

```json
{ "pickupCode": "1234", "assignmentId": "<uuid>", "assignmentVersion": 1 }
```

- **Coded handoff:** send all three (server requires them when a PENDING `DeliveryPickupHandoff` exists).
- **Legacy (no handoff row):** empty JSON body `{}`.
- **No invented `handoffRequired` field.**

### Current delivery fields used (truthful UI only)

`assignmentId`, `assignmentVersion`, `deliveryId`, `orderId`, `deliveryStatus`, `orderStatus`, `fulfillmentStatus`, `assignmentStatus`, `allowedActions`, `pickedUpAt`, `arrivedCustomerAt`, `deliveredAt`.

Confirm affordance = `allowedActions` contains `confirm-pickup` (not a fabricated flag).

---

## 4. Implemented user flow

1. Splash → restore secure session / `/auth/me` (requires `hasDriverProfile`).
2. Else phone OTP → verify → store tokens → current delivery.
3. Load current delivery; empty / error / ready states.
4. If `confirm-pickup` allowed: show 4-digit code field + primary CTA (legacy may leave code empty).
5. On confirm: wait for backend; on success clear code, show success, status `PICKED_UP` (or later allowed status from response).
6. On recoverable network / invalid / expired / locked: keep in-memory code; show French banner.
7. On assignment conflict / inactive: clear code, refresh current delivery, keep error message.
8. Logout clears session + in-memory pickup code.

---

## 5. Error / state mapping

| Code | French message |
| --- | --- |
| `PICKUP_HANDOFF_CODE_INVALID` | Code incorrect. Vérifiez le code auprès du commerçant. |
| `PICKUP_HANDOFF_EXPIRED` | Le code a expiré. Demandez au commerçant d’en générer un nouveau. |
| `PICKUP_HANDOFF_LOCKED` / `PICKUP_HANDOFF_RATE_LIMITED` | Trop de tentatives. Attendez ou demandez un nouveau code. |
| `PICKUP_HANDOFF_ASSIGNMENT_CONFLICT` | Cette affectation a changé. Actualisez la course. |
| `PICKUP_HANDOFF_INVALID_STATE` / `PICKUP_HANDOFF_ALREADY_CONSUMED` | La remise n’est plus disponible. Actualisez la course. |
| `DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE` | Cette affectation n’est plus active. |
| `DRIVER_DELIVERY_INVALID_STATE` / `DRIVER_DELIVERY_ACTION_NOT_ALLOWED` | Cette action n’est plus disponible. |
| Network / timeouts | Connexion impossible. Réessayez. |

Security notes:

- Pickup code never logged, never persisted; memory-only; cleared on success, logout, inactive/conflict.
- `Account.phone` not retained on `AuthMe` / not shown in delivery UI.
- No optimistic `PICKED_UP` transition.

---

## 6. Tests and analysis (exact results)

Commands (cwd `apps/driver_app`):

```text
dart format lib test
flutter analyze
flutter test
```

| Command | Result |
| --- | --- |
| `flutter analyze` | **No issues found!** |
| `flutter test` | **All tests passed!** (`+22`) |

Coverage includes: empty/load AT_PICKUP, coded success, legacy empty body, invalid/expired/locked codes, inactive assignment, invalid state + refresh, network preserve code, duplicate-submit prevention, digits clipping, 390×844 widget frames, text scale 1.3, keyboard `viewInsets`, incomplete-code disabled CTA, unauthenticated bootstrap → phone.

---

## 7. Evidence classification

| Evidence class | Status |
| --- | --- |
| Static inspection (backend + docs) | **Done** |
| Unit / widget tests | **Done** (`+29` on 2026-10-05; was `+22` at first slice) |
| Mocked capture | **Done** (widget harness / fakes) |
| Driver FR/AR + RTL + persist | **Done** (2026-10-05 batch) |
| Authenticated API (`:3100` / `speedygo_parity_fx`) | **PASS 24/24** — `fxenv_20261005T125234Z/driver_handoff/` (`H0–H1`, `A1–A4`, `P1–P18`; P9 labeled API fixture ≠ Driver UI) |
| Live Driver UI on device/simulator | **NOT VERIFIED** |
| Live Merchant–Driver pickup workflow | **NOT VERIFIED** |
| Merchant parity row 23 closure | **Still open** — see `docs/MERCHANT_DRIVER_PICKUP_HANDOFF_LIVE_CLOSE_REPORT_2026-10-05.md` |

---

## 8. Remaining blockers / gaps

1. Live Merchant–Driver UI handoff + FR/AR captures still required before row 23 can close (API e2e alone is insufficient).
2. Backend `assignmentVersion` expose remains local/uncommitted on the snapshot branch.
3. Driver still cannot advance earlier workflow steps (accept offer, start-to-pickup, arrive-pickup / GPS) in this slice — fixture must already be `AT_PICKUP` with `confirm-pickup` allowed.
4. `03_DRIVER_CONSISTENCY_LOCK.md` file missing from workspace; visual lock followed from task text only.
5. No dedicated `fx_*_handoff_live` harness yet (team/B7/daily-delay live scripts only).

---

## 9. Explicitly excluded (unchanged)

Driver onboarding/KYC, vehicles, availability/matching, offer acceptance, maps/GPS/ETA, customer delivery proof, COD/wallet/earnings, history, push, Admin/Customer source changes beyond the minimal backend response field, migrations, Redis/DB flushes, Merchant parity row closure without live proof, commit/push.

---

## 10. Confirmation

- No commit, push, force-push, merge, or history rewrite.
- No migrations applied to `speedygo_dev`.
- No destructive Redis/database flush tests.
- Work product remains local on `feat/driver-current-delivery-pickup-handoff-v1` (Driver) and uncommitted Backend snapshot working tree.
- Cross-app live close report: `docs/MERCHANT_DRIVER_PICKUP_HANDOFF_LIVE_CLOSE_REPORT_2026-10-05.md` (row 23 **not** closed; **75/77**).
