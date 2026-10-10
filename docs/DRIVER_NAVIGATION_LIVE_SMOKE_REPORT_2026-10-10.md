# Driver Navigation Live Smoke Report — 2026-10-10

## Status

**NAVIGATION LIVE SMOKE — PARTIAL PASS**

- A, B, D, F: **PASS** (`live_driver_ui_verified`)
- C: **NOT VERIFIED**
- E: **NOT RERUN** (prior Offers evidence retained)

No commit / push. Prior lifecycle evidence untouched.

## Environment

| Item | Value |
| --- | --- |
| Branch | `test/driver-post-accept-lifecycle-live-v1` |
| HEAD | `59f2013866b488016e6b6283235f6860d2bff318` |
| Backend | `3131c4ec…` read-only |
| API / DB / Redis | `:3100` / `speedygo_parity_fx` / index `9` |
| Simulator | iPhone 16e `8DB9007A-…` |
| Evidence | `docs/evidence/navigation_live_smoke_2026-10-10/` |

## Analyzer fix

Removed newly introduced `prefer_const_constructors` in `test/shell_navigation_test.dart` by using `const DriverMe` / `const DriverNavSnapshot`.  
`flutter analyze` → **2 info only** (pre-existing `locale_store`, `history_earnings_l10n`).

## Scenario results

| Scenario | Result | Expected | Actual | Classification |
| --- | --- | --- | --- | --- |
| A No-session cold start | PASS | `/auth/phone` | phone; Splash gone; Home redirect blocked | `live_driver_ui_verified` |
| B Approved, no delivery | PASS | `/home` + 4 tabs | Home; tabs; Profile avatar; nested vehicle; notifications return; AR locale preserves Home | `live_driver_ui_verified` |
| C Verification guards | NOT VERIFIED | pending/corrections/support | — | `not_verified` |
| D Active delivery cold start | PASS | `/delivery/current` | DRIVER_ASSIGNED; Home banner resume; relaunch restores stage | `live_driver_ui_verified` |
| E Offer accept transition | NOT RERUN | `/delivery/current` | — | `not_verified` |
| F Logout | PASS | phone stack replace | cancel stays Profile; confirm → phone; Home/Profile go blocked | `live_driver_ui_verified` |

Screenshots: 17 PNGs listed in `MANIFEST.json`.

## Four-tab clarification

`tab_root = 3` remains correct: Home Stitch folders are **state_variant** of `/home`; History / Earnings / Profile are the three `tab_root` rows. All four shell destinations are explicitly represented. Coverage folders = 47, `unreviewed = 0`.

## Failures found / fixes

1. Scenario B first run failed returning from Language (pushed outside shell) — fixed by popping Back until `nav_orders` visible; re-ran B → PASS.
2. No production navigation defect requiring code change beyond the smoke harness.

## Cleanup

- Released fixture assignments; secrets file removed; Redis `auth:parityfx:*` cleared on DB 9.
- No `FLUSHDB`. Remaining active assignments: 0.

## Prior lifecycle evidence

`docs/evidence/post_accept_lifecycle_live_2026-10-09/` — MANIFEST + **22** screenshots still present; not modified.
