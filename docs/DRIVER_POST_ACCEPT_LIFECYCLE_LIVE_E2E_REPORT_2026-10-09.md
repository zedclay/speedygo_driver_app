# Driver Post-Accept Delivery Lifecycle — Live E2E Report (2026-10-09)

## Status

**LIVE DRIVER POST-ACCEPT COD LIFECYCLE VERIFIED**

Non-COD live scenario: **NOT RUN** (see blockers).

No commit / push / merge / rebase performed.

---

## 1. Starting Git and environment

| Item | Value |
| --- | --- |
| Driver branch | `test/driver-post-accept-lifecycle-live-v1` (from `feat/driver-stitch-full-ui-v1`) |
| Driver HEAD | `59f2013866b488016e6b6283235f6860d2bff318` |
| Backend branch | `feat/driver-assignment-version-contract` |
| Backend SHA | `3131c4ec0e0d3295f1eeedf5e13f3cbdeb3c02b4` |
| Worktree at start | Clean at `59f2013`; live branch created for uncommitted evidence |
| API | `http://127.0.0.1:3100` / `PORT=3100` |
| Database | `speedygo_parity_fx` (Postgres `:5433`) |
| Redis | `redis://localhost:6381/9` |
| OTP transport | console (isolated capture) |
| Simulator | iPhone 16e `8DB9007A-B816-4EC5-86ED-C627AC60F2C5` |
| Disk before UI | ~11–13 Gi free on Data volume |
| Disk after | ~9.5 Gi free |
| Baseline tests | `flutter test` → **142/142 PASS** before live changes |

Isolation confirmed via process env (`DATABASE_URL` …`speedygo_parity_fx`, `REDIS_URL` …`/9`). No `speedygo_dev`, no migrations, no `FLUSHDB`, Maps/FCM/SMS/payment providers not activated.

---

## 2. Contract trace

Authoritative source: Backend Nest modules under `apps/backend/src/modules/delivery` and `.../cod`.

| Action | Endpoint | Required starting state | Location | Ending state | Event | Financial side effects | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Current delivery | `GET /driver/deliveries/current` | ACCEPTED unreleased assignment | — | read model + `allowedActions` | — | none | `driver-delivery.controller.ts` |
| Start toward pickup | `POST .../start-to-pickup` | `DRIVER_ASSIGNED` | no | `TO_PICKUP` | `DRIVER_STARTED_TO_PICKUP` | none | `driver-delivery.policy.ts` |
| Location update | `POST /driver/location` | authenticated Driver | body lat/lng | store refresh ≤45s | — | none | availability/location |
| Arrive pickup | `POST .../arrive-pickup` | `TO_PICKUP` | fresh ≤45s within 300m of live branch | `AT_PICKUP` | `DRIVER_ARRIVED_PICKUP` | none | policy + service |
| Pickup handoff read | `GET /merchant/{id}/orders/{orderId}/delivery/pickup-handoff` | Merchant owner; delivery at pickup | — | PENDING + code | — | none | merchant pickup handoff |
| Confirm pickup | `POST .../confirm-pickup` | `AT_PICKUP`; code + assignmentId/version when PENDING handoff | no | `PICKED_UP` (`pickedUpAt`) | `ORDER_PICKED_UP` | none (no COD/earning) | controller + handoff |
| Start delivery | `POST .../start-delivery` | `PICKED_UP` | no | `IN_TRANSIT` | `DELIVERY_IN_TRANSIT` | none | policy |
| Arrive customer | `POST .../arrive-customer` | `IN_TRANSIT` | fresh ≤45s within 300m of address snapshot | `ARRIVED_CUSTOMER` (`arrivedCustomerAt`) | `DRIVER_ARRIVED_CUSTOMER` | none | policy |
| Collect COD | `POST .../collect-cod` | `ARRIVED_CUSTOMER`; COD PENDING; exact amount | no | CodCollection COLLECTED; Payment SUCCEEDED | (COD domain) | COD once; **does not complete** | `driver-cod-collection.controller.ts` |
| Complete delivery | `POST .../complete-delivery` | `ARRIVED_CUSTOMER` + COD ready (COD) | no | `DELIVERED`; assignment RELEASED | `DELIVERY_COMPLETED` | one `DriverEarning` EARNED unpaid | controller description |
| History | `GET /driver/deliveries/history` | Driver auth | — | list | — | read | history controller |
| Earnings | `GET /driver/earnings` | Driver auth | — | list | — | read | earning controller |
| COD custody | `GET /driver/cod/summary` | Driver auth | — | custody summary | — | read | COD remittance controller |

Duplicate COD: same exact amount replays safely (reuse). Duplicate complete: rejected / no second event. Premature complete before COD: `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY` (HTTP 409).

`arrivedPickupAt` column: **N/A** — only event `DRIVER_ARRIVED_PICKUP`.

---

## 3. Fixture inventory

| Field | Value |
| --- | --- |
| Run ID | `fxlive_driver_lifecycle_20261009T235305Z` |
| Classification | **isolated deterministic fixture** (not matching-generated) |
| Order suffix | `a2120933` |
| Delivery suffix | `23dca11b` |
| Assignment suffix | `5a64bda6` / version `1` |
| Payment | COD `65000` minor |
| Start status | `DRIVER_ASSIGNED` (not pre-advanced) |
| Pickup handoff | Issued after live `arrive-pickup` via Merchant API |
| Branch / customer coords | `36.785,3.060` / `36.770,3.050` |

---

## 4. COD live scenario

| Step | Driver UI action | UI result | HTTP | Persistent state | Event | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Login | OTP Driver | Shell 4 tabs | 200 | session | — | PASS |
| Open current | `open_current_delivery` | DRIVER_ASSIGNED | 200 | ACCEPTED | — | PASS |
| Start to merchant | sticky start-to-pickup | TO_PICKUP | 200 | TO_PICKUP | STARTED_TO_PICKUP×1 | PASS |
| Arrive merchant | arrive-pickup + published location | AT_PICKUP | 200 | AT_PICKUP | ARRIVED_PICKUP×1 | PASS |
| Handoff | Merchant API fetch (fallback) | PENDING code (not logged) | 200 | PENDING | — | PASS (`authenticated_api`) |
| Confirm pickup | enter code + confirm | PICKED_UP; draft cleared | 200 | PICKED_UP; handoff CONSUMED | ORDER_PICKED_UP×1 | PASS |
| Relaunch | re-auth mid-flow | still PICKED_UP | 200 | unchanged | — | PASS |
| Start delivery | start-delivery | IN_TRANSIT | 200 | IN_TRANSIT | IN_TRANSIT×1 | PASS |
| Arrive customer | arrive-customer + dropoff location | ARRIVED_CUSTOMER + COD card | 200 | arrived_customer_at set | ARRIVED_CUSTOMER×1 | PASS |
| Premature complete | complete before COD | FR error mapped | 409 `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY` | still ARRIVED | no complete | PASS |
| Collect COD | exact 65000 via live COD UI | success; still ARRIVED | 200 | COLLECTED; Payment SUCCEEDED | — | PASS |
| Duplicate COD | collect disabled | onPressed null | — | count remains 1 | — | PASS |
| Complete | complete-delivery | DELIVERED banner | 200 | DELIVERED; assignment RELEASED | COMPLETED×1 | PASS |
| Post-complete | home / history / earnings | no active; history has item | 200 | earning×1; remittance 0 | — | PASS |

Evidence dir: `docs/evidence/post_accept_lifecycle_live_2026-10-09/`.

---

## 5. Non-COD scenario

**NOT RUN**

Blocker: isolated `fx_create_incoming.py` places COD-only checkout; no approved safe ELECTRONIC fixture that reaches `ARRIVED_CUSTOMER` with `Payment SUCCEEDED` without inventing payment provider success.

---

## 6. Negative gates

| Gate | Result |
| --- | --- |
| Premature completion | PASS — `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY` + truthful FR string |
| Duplicate COD | PASS — UI disabled after collect; DB count 1 |
| Duplicate completion | PASS — completion event ×1; assignment released |
| Invalid/stale refresh | PASS — refresh after complete → no active current |
| Relaunch mid-delivery | PASS — re-login restored PICKED_UP from server |
| Retry / uncertain response | PARTIAL — location arrive retried with fixture GPS; network fault injection not run |
| Pickup draft clear | PASS — code field gone after success |
| No Customer PIN | PASS — no PIN field |

Not run (optional): arrival without fresh location as dedicated negative (GPS faked for gate); start-delivery before pickup; stale assignment version.

---

## 7. Financial and event invariants

From `verify_cod.json`:

| Metric | Count / value |
| --- | --- |
| `ORDER_PICKED_UP` | 1 |
| COD collections | 1 / amount 65000 / COLLECTED |
| Payment | COD → SUCCEEDED |
| `DELIVERY_COMPLETED` | 1 |
| Driver earnings | 1 / net 15000 / EARNED |
| COD custody | summary API 200 (outstanding keys present) |
| Remittances | 0 |
| Allocations | 0 |
| Settlement fabricated | none |

Pickup did not create COD/earning/completion. COD did not auto-complete delivery.

---

## 8. Live UI evidence

22 screenshots under `docs/evidence/post_accept_lifecycle_live_2026-10-09/screenshots/` — see `MANIFEST.json` for locale, phase, class `live_driver_ui_verified`, sanitization.

Merchant pickup path class: **authenticated API fallback** (not `live_merchant_ui_verified`).

---

## 9. French / Arabic / RTL

| Locale | Result |
| --- | --- |
| French | Primary path PASS; COD-blocked error in French |
| Arabic | Checkpoints: accepted, TO_PICKUP, pickup entry, IN_TRANSIT, COD, delivered, history, earnings, home |
| RTL | Alignment OK in captured shots; back chevron RTL; amounts LTR-readable |
| Overflow / mixed EN | None observed in production strings on captured surfaces |
| Corrections | Extra scroll padding when COD visible under sticky complete (production) |

---

## 10. Tests and analyzer

Commands (post-live, Driver app):

```bash
dart format .
flutter analyze
flutter test
```

Final: `flutter test` → **142/142 PASS** (existing COD widget test strengthened with sticky-bar geometry assertion).  
`flutter analyze`: 2 pre-existing **info** diagnostics unchanged; no errors. Integration-test unused helper removed.

Harness added (uncommitted):

- `integration_test/live_post_accept_lifecycle_driver_test.dart`
- `integration_test/live_post_accept_lifecycle_resume_cod_test.dart`
- `docs/scripts/fx_live_lifecycle_*.py|sh`

---

## 11. Cleanup

| Action | Status |
| --- | --- |
| Fixture neutralize / assignment release | Done (`remainingActiveAssignments: 0`) |
| Secrets file removed | Done |
| Redis `auth:parityfx:*` on DB 9 | Cleared (no FLUSHDB) |
| Simulator app terminate | Done |
| Broad deletion | None |
| Evidence retained | screenshots / MANIFEST / report kept |

---

## 12. Git status

- Branch: `test/driver-post-accept-lifecycle-live-v1`
- HEAD: still `59f2013` (no commit)
- Uncommitted: evidence, harness scripts, integration tests, COD padding fix, widget regression assertion
- No push / merge / rebase / amend

---

## 13. Evidence status

| Claim | Status |
| --- | --- |
| Post-accept static inspection | PASS |
| Automated tests | PASS (baseline + regression) |
| Authenticated API | PASS |
| Database state | PASS |
| Live Driver UI | PASS |
| Live Merchant UI | NOT CLAIMED |
| Live Merchant–Driver handoff | PASS via API fallback + live Driver entry |
| COD lifecycle | PASS |
| Non-COD lifecycle | NOT RUN |
| Cross-app E2E | NOT CLAIMED |
| User acceptance | NOT CLAIMED |
| Release readiness | NOT CLAIMED |

---

## 14. Remaining blockers

1. **Non-COD live path** — no safe ELECTRONIC fixture in isolated create-incoming.
2. **Live Merchant UI handoff** — used authenticated Merchant API fallback; Merchant app UI not co-verified this run.
3. **Simulator Geolocator** — unreliable under `flutter test`; fixture GPS injected via `FakeDeviceLocationSource` while still publishing live to `/driver/location`.
4. **Customer delivery PIN** — intentionally not implemented (proofless MVP).
5. **Maps / call / chat** — unavailable by design (`nav_unavailable` honest).
6. **Network-fault negative** — not instrumented as a dedicated gate.
7. **Product** — sticky complete can still compete with COD UX; padding mitigates hit-test; consider disabling sticky complete until COD collected.

---

## 15. Final conclusion

**LIVE DRIVER POST-ACCEPT COD LIFECYCLE VERIFIED**

Server-confirmed transitions from accepted current delivery through merchant arrive, secure pickup handoff (API-sourced code + live Driver entry), customer arrive, COD gate, exact COD collection once, completion once, history/earnings/COD custody readback — on isolated `:3100` / `speedygo_parity_fx` / Redis `9` with live Flutter UI on iPhone 16e.

Non-COD: **NOT RUN**. Not release-ready. Not user-accepted.
