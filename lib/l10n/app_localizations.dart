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
