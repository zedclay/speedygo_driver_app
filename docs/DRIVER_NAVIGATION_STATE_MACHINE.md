# Driver Navigation State Machine (2026-10-10)

Authoritative client navigation model for `apps/driver_app`.  
Backend delivery/onboarding contracts remain source of truth for business progress.

Machine-readable companion: `DRIVER_NAVIGATION_STATE_MACHINE.json`.

## Lanes

| Lane | Who | Root surfaces |
| --- | --- | --- |
| Cold start | Everyone | `/` Splash (not kept in back stack) |
| Authentication | Signed out | `/auth/phone` → `/auth/otp` |
| Onboarding | Profile incomplete / UNVERIFIED / REJECTED / PENDING_REVIEW | `/onboarding/*` |
| Approved shell | `verificationStatus == APPROVED` | StatefulShell: Home / History / Earnings / Profile |
| Active delivery | Approved + current delivery | `/delivery/current` (single screen, state variants) |
| Nested profile | Approved | `/profile/*`, `/settings/*`, `/support/*`, `/notifications` |
| Blocked contextual | From delivery/settings help | `/blocked/:kind` (honest unavailable) |

## Cold start algorithm

```
Splash (initialLocation)
  → restore locale
  → SessionController.restore()
  → DriverBootstrapController.resolveAfterSession()
       GET /driver/me when signedIn
       GET /driver/deliveries/current when APPROVED
  → context.go(destination)   // replace; Splash not in history
```

| Condition | Destination |
| --- | --- |
| No / invalid session | `/auth/phone` |
| Account without driver profile | `/onboarding/profile` |
| UNVERIFIED incomplete steps | first incomplete onboarding step |
| PENDING_REVIEW | `/onboarding/pending` |
| REJECTED | `/onboarding/corrections` |
| Account SUSPENDED / INACTIVE | `/support` |
| APPROVED + active delivery | `/delivery/current` |
| APPROVED + no active delivery | `/home` |

Implementation: `lib/app/router/driver_navigation_resolver.dart`, `driver_bootstrap_controller.dart`.

## Route guards (`driverRedirect`)

- `unknown` → force Splash (except language).
- `signedOut` → phone (Splash redirects to phone; language allowed).
- `needsDriverProfile` → onboarding only (+ language).
- `signedIn` + resolved snapshot:
  - PENDING_REVIEW → cannot enter shell/delivery; pending + language + support only.
  - REJECTED → onboarding (+ language/support) only.
  - UNVERIFIED → onboarding only.
  - APPROVED → shell/delivery allowed; editable onboarding routes bounce to Home or current delivery.
- Language settings never reset auth or delivery.

## Availability / offers

Home is **one route** (`/home`) with visual states: Offline, Online waiting, Offer card, Active-delivery banner.  
Not a sequential slideshow of Stitch folders.

| Event | Navigation |
| --- | --- |
| Go online / offline | stay `/home` |
| Reject / expire offer | stay `/home` waiting |
| Accept success | `markActiveDelivery(true)` → `/delivery/current` |
| Accept conflict | refresh server; stay `/home` or resolve again |

## Active delivery

Single Flutter screen `/delivery/current`. Stage = `deliveryStatus` from Backend.

| State | Primary action | Location | Next |
| --- | --- | --- | --- |
| DRIVER_ASSIGNED | start-to-pickup | no | TO_PICKUP |
| TO_PICKUP | arrive-pickup | yes ≤45s / 300m branch | AT_PICKUP |
| AT_PICKUP | confirm-pickup (+ code when handoff PENDING) | no | PICKED_UP |
| PICKED_UP | start-delivery | no | IN_TRANSIT |
| IN_TRANSIT | arrive-customer | yes ≤45s / 300m snapshot | ARRIVED_CUSTOMER |
| ARRIVED_CUSTOMER | collect-cod if COD; then complete-delivery | no | DELIVERED |
| DELIVERED | acknowledge | — | `/home` (clear active flag) |

Back from delivery: always `context.go(/home)` (replace). Never return to an offer.  
Relaunch: Splash → bootstrap → `/delivery/current` if server still has current delivery.  
Blocked children (`contact`, `delivery-pin`, `failure-report`, `maps`): push `/blocked/:kind`, pop to same delivery stage. Not lifecycle steps.

Customer PIN: blocked. Maps SDK: deferred (`nav_unavailable`). COD gating: server `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY`.

## Shell / profile / logout

- Four tabs only for approved Drivers (redirect enforced when snapshot resolved).
- Profile avatar → Profile tab; logout only via Profile confirmation.
- Notifications / settings / vehicle / documents / ratings / support: push, pop to parent.
- Confirm logout → clear session → replace stack with phone.
- Cancel logout → stay on Profile.

## Onboarding progression

1. Profile → 2. Identity → 3. Driving licence (Backend currently always required; vehicle types MOTORCYCLE|SCOOTER|CAR) → 4. Vehicle → 5. Review → submit → Pending.  
Corrections (REJECTED) → editable steps → resubmit → Pending.  
Approved celebration (`/onboarding/approved`) is one-shot CTA to Home; cold start never lands there for every launch.

## 47 Stitch folders

See JSON `screens[]` for classification (`sequential_step`, `state_variant`, `tab_root`, `nested_detail`, `modal`, `blocked_contract`, `not_applicable_duplicate`) and coverage decision. Stitch folder order is **not** the production route order.

### Four-tab shell mapping clarification

| Shell tab | Stitch folder (representative) | Classification | Why |
| --- | --- | --- | --- |
| Home / current work | `accueil_en_ligne_fonctionnel` (+ offline/offer variants) | **state_variant** | One `/home` route; Offline/Online/Offer/Active-banner are states, not separate tab roots |
| History | `historique_des_livraisons` | **tab_root** | Shell branch `/history` |
| Earnings | `gains_et_totaux_op_rationnels` | **tab_root** | Shell branch `/earnings` |
| Profile | `profil_du_chauffeur` | **tab_root** | Shell branch `/profile` |

Therefore `tab_root = 3` is intentional: Home is deliberately **not** counted as a tab_root row because its Stitch folders are state variants of a single shell destination. Coverage still lists all four destinations; `unreviewed = 0`; folder total remains **47**.
