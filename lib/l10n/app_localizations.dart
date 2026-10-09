import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'SpeedyGo Driver'**
  String get appName;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessayez.'**
  String get networkError;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get unexpectedError;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Reconnectez-vous.'**
  String get sessionExpired;

  /// No description provided for @phoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion livreur'**
  String get phoneTitle;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneHint;

  /// No description provided for @phoneContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get phoneContinue;

  /// No description provided for @phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro valide.'**
  String get phoneInvalid;

  /// No description provided for @otpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get otpTitle;

  /// No description provided for @otpHint.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par SMS'**
  String get otpHint;

  /// No description provided for @otpVerify.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get otpVerify;

  /// No description provided for @otpResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get otpResend;

  /// No description provided for @deliveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Course en cours'**
  String get deliveryTitle;

  /// No description provided for @deliveryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune course active pour le moment.'**
  String get deliveryEmpty;

  /// No description provided for @deliveryRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get deliveryRefresh;

  /// No description provided for @deliveryLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la course…'**
  String get deliveryLoading;

  /// No description provided for @confirmPickup.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la prise en charge'**
  String get confirmPickup;

  /// No description provided for @confirmingPickup.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation…'**
  String get confirmingPickup;

  /// No description provided for @pickupCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code commerçant'**
  String get pickupCodeLabel;

  /// No description provided for @pickupCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres'**
  String get pickupCodeHint;

  /// No description provided for @pickupCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demandez le code affiché par le commerçant. Laissez vide uniquement si aucun code n’est requis.'**
  String get pickupCodeHelp;

  /// No description provided for @pickedUpSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Prise en charge confirmée.'**
  String get pickedUpSuccess;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez vous reconnecter pour continuer.'**
  String get logoutConfirmBody;

  /// No description provided for @logoutConfirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutConfirmAction;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @statusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statusLabel;

  /// No description provided for @orderIdLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get orderIdLabel;

  /// No description provided for @assignmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Affectation'**
  String get assignmentLabel;

  /// No description provided for @noDriverProfile.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil livreur n’est associé à ce compte.'**
  String get noDriverProfile;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la langue de l’application livreur. Le changement s’applique immédiatement sans déconnexion.'**
  String get languageSettingsSubtitle;

  /// No description provided for @languageOptionFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageOptionFrench;

  /// No description provided for @languageOptionArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get languageOptionArabic;

  /// No description provided for @languageApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les modifications'**
  String get languageApply;

  /// No description provided for @languagePreviewNote.
  ///
  /// In fr, this message translates to:
  /// **'Les numéros de téléphone et codes de prise en charge restent lisibles de gauche à droite.'**
  String get languagePreviewNote;

  /// No description provided for @codeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Vérifiez le code auprès du commerçant.'**
  String get codeInvalid;

  /// No description provided for @codeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Le code a expiré. Demandez au commerçant d’en générer un nouveau.'**
  String get codeExpired;

  /// No description provided for @codeLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Attendez ou demandez un nouveau code.'**
  String get codeLocked;

  /// No description provided for @assignmentInactive.
  ///
  /// In fr, this message translates to:
  /// **'Cette affectation n’est plus active.'**
  String get assignmentInactive;

  /// No description provided for @invalidState.
  ///
  /// In fr, this message translates to:
  /// **'Cette action n’est plus disponible.'**
  String get invalidState;

  /// No description provided for @handoffInvalidState.
  ///
  /// In fr, this message translates to:
  /// **'La remise n’est plus disponible. Actualisez la course.'**
  String get handoffInvalidState;

  /// No description provided for @assignmentConflict.
  ///
  /// In fr, this message translates to:
  /// **'Cette affectation a changé. Actualisez la course.'**
  String get assignmentConflict;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get homeTitle;

  /// No description provided for @homeLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la disponibilité…'**
  String get homeLoading;

  /// No description provided for @availabilityOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get availabilityOnline;

  /// No description provided for @availabilityOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get availabilityOffline;

  /// No description provided for @availabilitySuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get availabilitySuspended;

  /// No description provided for @availabilityOfflineAfterCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne après la course en cours'**
  String get availabilityOfflineAfterCurrent;

  /// No description provided for @goOnline.
  ///
  /// In fr, this message translates to:
  /// **'Passer en ligne'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In fr, this message translates to:
  /// **'Passer hors ligne'**
  String get goOffline;

  /// No description provided for @goingOnline.
  ///
  /// In fr, this message translates to:
  /// **'Mise en ligne…'**
  String get goingOnline;

  /// No description provided for @goingOffline.
  ///
  /// In fr, this message translates to:
  /// **'Mise hors ligne…'**
  String get goingOffline;

  /// No description provided for @waitingForOffer.
  ///
  /// In fr, this message translates to:
  /// **'En attente d’une offre…'**
  String get waitingForOffer;

  /// No description provided for @waitingForOfferHint.
  ///
  /// In fr, this message translates to:
  /// **'Restez en ligne avec la localisation active pour recevoir des offres.'**
  String get waitingForOfferHint;

  /// No description provided for @offerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Offre de livraison'**
  String get offerTitle;

  /// No description provided for @offerCountdownLabel.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans'**
  String get offerCountdownLabel;

  /// No description provided for @offerExpired.
  ///
  /// In fr, this message translates to:
  /// **'Cette offre a expiré.'**
  String get offerExpired;

  /// No description provided for @offerAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get offerAccept;

  /// No description provided for @offerReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get offerReject;

  /// No description provided for @offerAccepting.
  ///
  /// In fr, this message translates to:
  /// **'Acceptation…'**
  String get offerAccepting;

  /// No description provided for @offerRejecting.
  ///
  /// In fr, this message translates to:
  /// **'Refus…'**
  String get offerRejecting;

  /// No description provided for @offerPickupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Retrait chez'**
  String get offerPickupLabel;

  /// No description provided for @offerRemunerationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rémunération'**
  String get offerRemunerationLabel;

  /// No description provided for @offerPickupDistanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Distance retrait'**
  String get offerPickupDistanceLabel;

  /// No description provided for @offerDeliveryDistanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Distance livraison'**
  String get offerDeliveryDistanceLabel;

  /// No description provided for @offerOrderRefLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get offerOrderRefLabel;

  /// No description provided for @openCurrentDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la course en cours'**
  String get openCurrentDelivery;

  /// No description provided for @activeDeliveryBanner.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez une course active. Terminez-la avant de nouvelles offres.'**
  String get activeDeliveryBanner;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Activez les services de localisation sur l’appareil.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'L’autorisation de localisation est requise pour recevoir et accepter des offres.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée définitivement. Activez-la dans les réglages système.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’obtenir la position.'**
  String get locationUnavailable;

  /// No description provided for @locationTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé pour obtenir la position.'**
  String get locationTimeout;

  /// No description provided for @locationPublishing.
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la position…'**
  String get locationPublishing;

  /// No description provided for @driverNotApproved.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n’est pas encore approuvé. Terminez la vérification.'**
  String get driverNotApproved;

  /// No description provided for @driverNotOperational.
  ///
  /// In fr, this message translates to:
  /// **'Profil non opérationnel (documents ou véhicule incomplets).'**
  String get driverNotOperational;

  /// No description provided for @driverAvailabilityInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de changer la disponibilité. Actualisez puis réessayez.'**
  String get driverAvailabilityInvalid;

  /// No description provided for @offerTakenOrStale.
  ///
  /// In fr, this message translates to:
  /// **'Cette offre n’est plus disponible.'**
  String get offerTakenOrStale;

  /// No description provided for @offerLocationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Une position récente est requise pour accepter l’offre.'**
  String get offerLocationRequired;

  /// No description provided for @offerLocationStale.
  ///
  /// In fr, this message translates to:
  /// **'Votre position est obsolète. Réessayez après actualisation.'**
  String get offerLocationStale;

  /// No description provided for @notMatchingEligible.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’êtes pas éligible au matching pour le moment.'**
  String get notMatchingEligible;

  /// No description provided for @metersUnit.
  ///
  /// In fr, this message translates to:
  /// **'m'**
  String get metersUnit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
