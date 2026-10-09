# Driver Stitch 47-screen inventory

Date: 2026-10-09  
Source: `screens/DriverScreens/stitch_speedygo_driver_mobile_app.zip` (47 `screen.png` pairs)  
Baseline branch head: `be7cedd` (Availability & Offers V1 — protected)  
Implementation branch: `feat/driver-stitch-full-ui-v1`

## Legend

| Status | Meaning |
| --- | --- |
| LIVE | Server-backed UI verified on Offers V1 / pickup handoff |
| WIP | Implemented on Stitch branch (see coverage matrix for final decisions) |
| BLOCKED | No backend contract — honest unavailable screen only |
| VISUAL | Stitch composition only; no invented API |

Authoritative classification counts: `DRIVER_STITCH_SCREEN_COVERAGE.json` (47 rows, `unreviewed = 0`).  
Final automated suite for Stitch preservation: **142/142 PASS** (63/63 = Offers baseline; 104/104 = intermediate only).

## Matrix

| # | Stitch folder | Flow role | App route / surface | Contract | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | `splash_and_session_routing` | Session gate | `/` | `/auth/me`, tokens | LIVE |
| 2 | `connexion_chauffeur_t_l_phone` | Auth phone | `/auth/phone` | OTP request | LIVE |
| 3 | `v_rification_otp_chauffeur` | Auth OTP | `/auth/otp` | OTP verify | LIVE |
| 4 | `inscription_chauffeur` | Onboarding profile | `/onboarding/profile` | `POST/PATCH /driver/profile` | WIP |
| 5 | `t_l_chargement_pi_ce_d_identit` | Onboarding ID | `/onboarding/identity` | Documents upload | WIP |
| 6 | `t_l_chargement_permis_de_conduire` | Onboarding license | `/onboarding/license` | Documents upload | WIP |
| 7 | `informations_du_v_hicule_1` | Onboarding vehicle | `/onboarding/vehicle` | Vehicles | WIP |
| 8 | `informations_du_v_hicule_2` | Vehicle edit | `/profile/vehicle` | Vehicles | WIP |
| 9 | `mes_documents_chauffeur` | Documents hub | `/profile/documents` | Documents | WIP |
| 10 | `r_vision_de_la_v_rification` | Submit review | `/onboarding/review` | Verification submit | WIP |
| 11 | `soumission_des_corrections_optimis_e` | Corrections | `/onboarding/corrections` | Profile/docs | WIP |
| 12 | `v_rification_en_attente` | Pending | `/onboarding/pending` | `/driver/me` | WIP |
| 13 | `v_rification_approuv_e` | Approved | `/onboarding/approved` | `/driver/me` | WIP |
| 14 | `accueil_hors_ligne_fonctionnel` | Home offline | `/home` | go-offline / me | LIVE |
| 15 | `accueil_hors_ligne_banni_re_demande` | Home offline + offer | `/home` | current-offer | LIVE |
| 16 | `accueil_hors_ligne_menu_hamburger` | Home chrome (drawer ref) | Shell top bar | — | WIP (shell, no drawer) |
| 17 | `accueil_hors_ligne_support_statut_pur` | Home offline status | `/home` | `/driver/me` | LIVE |
| 18 | `accueil_en_ligne_fonctionnel` | Home online | `/home` | go-online | LIVE |
| 19 | `accueil_en_ligne_perfect_sync` | Home online + location | `/home` | `POST /driver/location` | LIVE |
| 20 | `accueil_en_ligne_support_statut_pur` | Home online status | `/home` | `/driver/me` | LIVE |
| 21 | `accueil_en_ligne_menu_hamburger_drawer_bleu` | Drawer (Stitch) | Shell | — | VISUAL → shell NavBar |
| 22 | `accueil_en_ligne_menu_hamburger_top_bar_bleue` | Top bar | Shell | — | WIP |
| 23 | `d_tails_de_la_course_00_45_privacy` | Offer detail / sticky | `/home` offer card | accept/reject | LIVE |
| 24 | `navigation_vers_le_marchand` | To merchant | `/delivery/current` | start-to-pickup | WIP lifecycle |
| 25 | `arriv_chez_le_marchand` | At merchant | `/delivery/current` | arrive-pickup (+ GPS) | WIP lifecycle |
| 26 | `en_attente_de_pr_paration` | Prep wait | `/delivery/current` AT_PICKUP | poll current | WIP lifecycle |
| 27 | `confirmation_du_retrait_pin_s_curis` | Pickup handoff PIN | `/delivery/current` | confirm-pickup | LIVE (preserve) |
| 28 | `navigation_vers_le_client` | To customer | `/delivery/current` | start-delivery | WIP lifecycle |
| 29 | `chauffeur_proximit` | Near customer | `/delivery/current` | arrive-customer (+ GPS) | WIP lifecycle |
| 30 | `validation_du_code_de_livraison` | Customer delivery PIN | blocked | no contract | BLOCKED |
| 31 | `livraison_termin_e` | Delivered | `/delivery/current` | complete-delivery | WIP lifecycle |
| 32 | `r_conciliation_de_caisse` | COD / remittance | earnings + COD card | collect-cod / remittances | WIP |
| 33 | `chec_de_livraison` | Failure | blocked | no contract | BLOCKED |
| 34 | `signalement_de_probl_me_de_livraison` | Problem report | blocked | no contract | BLOCKED |
| 35 | `contact_marchand` | Contact merchant | blocked | no proxy | BLOCKED |
| 36 | `contact_client` | Contact customer | blocked | no proxy | BLOCKED |
| 37 | `historique_des_livraisons` | History list | `/history` | `/driver/deliveries/history` | WIP |
| 38 | `d_tails_de_livraison_historique` | History detail | `/history/detail/:id` | history/:id | WIP |
| 39 | `gains_et_totaux_op_rationnels` | Earnings | `/earnings` | earnings + COD summary | WIP |
| 40 | `profil_du_chauffeur` | Profile | `/profile` | `/driver/me` | WIP |
| 41 | `param_tres_du_chauffeur` | Settings hub | `/settings` | language + links | WIP |
| 42 | `param_tres_de_langue_et_notifications` | Language / prefs | `/settings/language` + blocked prefs | locale | LIVE language / BLOCKED prefs |
| 43 | `notifications_chauffeur_haute_demande` | Inbox | `/notifications` | `/notifications` | WIP |
| 44 | `aide_support` | Support list | `/support` | `/driver/support` | WIP |
| 45 | `support_ticket_detail` | Support detail | `/support/detail/:id` | support/:id | WIP |
| 46 | `notes_et_commentaires_du_chauffeur` | Ratings | `/profile/ratings` | ratings summary | WIP |
| 47 | `d_connexion_confirmation` | Logout confirm | Profile / sheet | logout | WIP (shell) |

## Protected baselines (do not regress)

1. **Availability & Offers V1** — `be7cedd`, evidence `docs/evidence/availability_offers_live_2026-10-09/`, report `docs/DRIVER_AVAILABILITY_AND_OFFERS_V1_REPORT_2026-10-09.md`. Matching runtime VERIFIED. Do not rematch unless availability/location/polling/offer/session routing changes.
2. **Pickup handoff** — confirm-pickup + 4-digit merchant code path and its evidence/tests remain authoritative.

## Priority implementation order (this batch)

1. Accepted offer → start-to-pickup → merchant nav (honest, no Maps SDK)
2. arrive-pickup (location publish + GPS gate)
3. Prep / wait at AT_PICKUP → existing pickup handoff
4. start-delivery → arrive-customer → COD collect → complete-delivery
5. Shell / history / earnings / profile / onboarding (visual + existing contracts)
6. Blocked honest screens for contact / failure / delivery PIN / maps / notification prefs

## Maps / address policy

Current delivery DTO exposes no merchant/customer address. Navigation cards are **honest unavailable** (no invented coordinates, no Maps SDK). Location is only used for server GPS gates via `POST /driver/location`.
