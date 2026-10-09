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
}
