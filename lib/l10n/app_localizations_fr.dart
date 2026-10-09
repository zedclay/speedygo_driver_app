// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'SpeedyGo Driver';

  @override
  String get networkError => 'Connexion impossible. Réessayez.';

  @override
  String get unexpectedError => 'Une erreur est survenue. Réessayez.';

  @override
  String get sessionExpired => 'Session expirée. Reconnectez-vous.';

  @override
  String get phoneTitle => 'Connexion livreur';

  @override
  String get phoneHint => 'Numéro de téléphone';

  @override
  String get phoneContinue => 'Continuer';

  @override
  String get phoneInvalid => 'Saisissez un numéro valide.';

  @override
  String get otpTitle => 'Code de vérification';

  @override
  String get otpHint => 'Code reçu par SMS';

  @override
  String get otpVerify => 'Valider';

  @override
  String get otpResend => 'Renvoyer le code';

  @override
  String get deliveryTitle => 'Course en cours';

  @override
  String get deliveryEmpty => 'Aucune course active pour le moment.';

  @override
  String get deliveryRefresh => 'Actualiser';

  @override
  String get deliveryLoading => 'Chargement de la course…';

  @override
  String get confirmPickup => 'Confirmer la prise en charge';

  @override
  String get confirmingPickup => 'Confirmation…';

  @override
  String get pickupCodeLabel => 'Code commerçant';

  @override
  String get pickupCodeHint => '4 chiffres';

  @override
  String get pickupCodeHelp =>
      'Demandez le code affiché par le commerçant. Laissez vide uniquement si aucun code n’est requis.';

  @override
  String get pickedUpSuccess => 'Prise en charge confirmée.';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody =>
      'Vous devrez vous reconnecter pour continuer.';

  @override
  String get logoutConfirmAction => 'Se déconnecter';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get statusLabel => 'Statut';

  @override
  String get orderIdLabel => 'Commande';

  @override
  String get assignmentLabel => 'Affectation';

  @override
  String get noDriverProfile =>
      'Aucun profil livreur n’est associé à ce compte.';

  @override
  String get languageSettingsTitle => 'Langue';

  @override
  String get languageSettingsSubtitle =>
      'Choisissez la langue de l’application livreur. Le changement s’applique immédiatement sans déconnexion.';

  @override
  String get languageOptionFrench => 'Français';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageApply => 'Appliquer les modifications';

  @override
  String get languagePreviewNote =>
      'Les numéros de téléphone et codes de prise en charge restent lisibles de gauche à droite.';

  @override
  String get codeInvalid =>
      'Code incorrect. Vérifiez le code auprès du commerçant.';

  @override
  String get codeExpired =>
      'Le code a expiré. Demandez au commerçant d’en générer un nouveau.';

  @override
  String get codeLocked =>
      'Trop de tentatives. Attendez ou demandez un nouveau code.';

  @override
  String get assignmentInactive => 'Cette affectation n’est plus active.';

  @override
  String get invalidState => 'Cette action n’est plus disponible.';

  @override
  String get handoffInvalidState =>
      'La remise n’est plus disponible. Actualisez la course.';

  @override
  String get assignmentConflict =>
      'Cette affectation a changé. Actualisez la course.';

  @override
  String get homeTitle => 'Disponibilité';

  @override
  String get homeLoading => 'Chargement de la disponibilité…';

  @override
  String get availabilityOnline => 'En ligne';

  @override
  String get availabilityOffline => 'Hors ligne';

  @override
  String get availabilitySuspended => 'Suspendu';

  @override
  String get availabilityOfflineAfterCurrent =>
      'Hors ligne après la course en cours';

  @override
  String get goOnline => 'Passer en ligne';

  @override
  String get goOffline => 'Passer hors ligne';

  @override
  String get goingOnline => 'Mise en ligne…';

  @override
  String get goingOffline => 'Mise hors ligne…';

  @override
  String get waitingForOffer => 'En attente d’une offre…';

  @override
  String get waitingForOfferHint =>
      'Restez en ligne avec la localisation active pour recevoir des offres.';

  @override
  String get offerTitle => 'Offre de livraison';

  @override
  String get offerCountdownLabel => 'Expire dans';

  @override
  String get offerExpired => 'Cette offre a expiré.';

  @override
  String get offerAccept => 'Accepter';

  @override
  String get offerReject => 'Refuser';

  @override
  String get offerAccepting => 'Acceptation…';

  @override
  String get offerRejecting => 'Refus…';

  @override
  String get offerPickupLabel => 'Retrait chez';

  @override
  String get offerRemunerationLabel => 'Rémunération';

  @override
  String get offerPickupDistanceLabel => 'Distance retrait';

  @override
  String get offerDeliveryDistanceLabel => 'Distance livraison';

  @override
  String get offerOrderRefLabel => 'Référence';

  @override
  String get openCurrentDelivery => 'Ouvrir la course en cours';

  @override
  String get activeDeliveryBanner =>
      'Vous avez une course active. Terminez-la avant de nouvelles offres.';

  @override
  String get locationServicesDisabled =>
      'Activez les services de localisation sur l’appareil.';

  @override
  String get locationPermissionDenied =>
      'L’autorisation de localisation est requise pour recevoir et accepter des offres.';

  @override
  String get locationPermissionDeniedForever =>
      'Localisation refusée définitivement. Activez-la dans les réglages système.';

  @override
  String get locationUnavailable => 'Impossible d’obtenir la position.';

  @override
  String get locationTimeout => 'Délai dépassé pour obtenir la position.';

  @override
  String get locationPublishing => 'Envoi de la position…';

  @override
  String get driverNotApproved =>
      'Votre compte n’est pas encore approuvé. Terminez la vérification.';

  @override
  String get driverNotOperational =>
      'Profil non opérationnel (documents ou véhicule incomplets).';

  @override
  String get driverAvailabilityInvalid =>
      'Impossible de changer la disponibilité. Actualisez puis réessayez.';

  @override
  String get offerTakenOrStale => 'Cette offre n’est plus disponible.';

  @override
  String get offerLocationRequired =>
      'Une position récente est requise pour accepter l’offre.';

  @override
  String get offerLocationStale =>
      'Votre position est obsolète. Réessayez après actualisation.';

  @override
  String get notMatchingEligible =>
      'Vous n’êtes pas éligible au matching pour le moment.';

  @override
  String get metersUnit => 'm';
}
