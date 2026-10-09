/// Driver UI copy — French (fallback) and Arabic on one shared code path.
///
/// Bind the active language via [bind] whenever the app locale changes.
/// Never store OTP, tokens, or pickup codes here.
class AppStrings {
  AppStrings._();

  static String _code = 'fr';

  static void bind(String languageCode) {
    _code = languageCode == 'ar' ? 'ar' : 'fr';
  }

  static bool get isArabic => _code == 'ar';
  static String get languageCode => _code;

  static String get appName => isArabic ? 'SpeedyGo سائق' : 'SpeedyGo Driver';

  static String get networkError => isArabic
      ? 'تعذّر الاتصال. أعد المحاولة.'
      : 'Connexion impossible. Réessayez.';

  static String get unexpectedError => isArabic
      ? 'حدث خطأ. أعد المحاولة.'
      : 'Une erreur est survenue. Réessayez.';

  static String get sessionExpired => isArabic
      ? 'انتهت الجلسة. سجّل الدخول مجددًا.'
      : 'Session expirée. Reconnectez-vous.';

  static String get phoneTitle =>
      isArabic ? 'تسجيل دخول السائق' : 'Connexion livreur';

  static String get phoneHint =>
      isArabic ? 'رقم الهاتف' : 'Numéro de téléphone';

  static String get phoneContinue => isArabic ? 'متابعة' : 'Continuer';

  static String get phoneInvalid =>
      isArabic ? 'أدخل رقمًا صالحًا.' : 'Saisissez un numéro valide.';

  static String get otpTitle =>
      isArabic ? 'رمز التحقق' : 'Code de vérification';

  static String get otpHint =>
      isArabic ? 'الرمز المستلم عبر الرسالة' : 'Code reçu par SMS';

  static String get otpVerify => isArabic ? 'تأكيد' : 'Valider';

  static String get otpResend =>
      isArabic ? 'إعادة إرسال الرمز' : 'Renvoyer le code';

  static String get deliveryTitle =>
      isArabic ? 'الطلب الحالي' : 'Course en cours';

  static String get deliveryEmpty => isArabic
      ? 'لا توجد طلبية نشطة حاليًا.'
      : 'Aucune course active pour le moment.';

  static String get deliveryRefresh => isArabic ? 'تحديث' : 'Actualiser';

  static String get deliveryLoading =>
      isArabic ? 'جاري تحميل الطلبية…' : 'Chargement de la course…';

  static String get confirmPickup =>
      isArabic ? 'تأكيد الاستلام' : 'Confirmer la prise en charge';

  static String get confirmingPickup =>
      isArabic ? 'جاري التأكيد…' : 'Confirmation…';

  static String get pickupCodeLabel =>
      isArabic ? 'رمز التاجر' : 'Code commerçant';

  static String get pickupCodeHint => isArabic ? '٤ أرقام' : '4 chiffres';

  static String get pickupCodeHelp => isArabic
      ? 'اطلب الرمز المعروض لدى التاجر. اتركه فارغًا فقط إذا لم يُطلب رمز.'
      : 'Demandez le code affiché par le commerçant. Laissez vide uniquement si aucun code n’est requis.';

  static String get pickedUpSuccess =>
      isArabic ? 'تم تأكيد الاستلام.' : 'Prise en charge confirmée.';

  static String get logout => isArabic ? 'تسجيل الخروج' : 'Se déconnecter';

  static String get logoutConfirmTitle =>
      isArabic ? 'تسجيل الخروج؟' : 'Se déconnecter ?';

  static String get logoutConfirmBody => isArabic
      ? 'ستحتاج إلى إعادة تسجيل الدخول للمتابعة.'
      : 'Vous devrez vous reconnecter pour continuer.';

  static String get logoutConfirmAction =>
      isArabic ? 'تسجيل الخروج' : 'Se déconnecter';

  static String get cancel => isArabic ? 'إلغاء' : 'Annuler';

  static String get retry => isArabic ? 'إعادة المحاولة' : 'Réessayer';

  static String get statusLabel => isArabic ? 'الحالة' : 'Statut';

  static String get orderIdLabel => isArabic ? 'الطلب' : 'Commande';

  static String get assignmentLabel => isArabic ? 'التعيين' : 'Affectation';

  static String get noDriverProfile => isArabic
      ? 'لا يوجد ملف سائق مرتبط بهذا الحساب.'
      : 'Aucun profil livreur n’est associé à ce compte.';

  static String get languageSettingsTitle => isArabic ? 'اللغة' : 'Langue';

  static String get languageSettingsSubtitle => isArabic
      ? 'اختر لغة واجهة السائق. يُطبَّق التغيير فورًا دون تسجيل الخروج.'
      : 'Choisissez la langue de l’application livreur. Le changement s’applique immédiatement sans déconnexion.';

  static String get languageOptionFrench => 'Français';

  static String get languageOptionArabic => 'العربية';

  static String get languageApply =>
      isArabic ? 'تطبيق' : 'Appliquer les modifications';

  static String get languagePreviewNote => isArabic
      ? 'أرقام الهاتف ورموز الاستلام تبقى قابلة للقراءة من اليسار إلى اليمين.'
      : 'Les numéros de téléphone et codes de prise en charge restent lisibles de gauche à droite.';

  static String get codeInvalid => isArabic
      ? 'رمز غير صحيح. تحقّق منه لدى التاجر.'
      : 'Code incorrect. Vérifiez le code auprès du commerçant.';

  static String get codeExpired => isArabic
      ? 'انتهت صلاحية الرمز. اطلب من التاجر إنشاء رمز جديد.'
      : 'Le code a expiré. Demandez au commerçant d’en générer un nouveau.';

  static String get codeLocked => isArabic
      ? 'محاولات كثيرة. انتظر أو اطلب رمزًا جديدًا.'
      : 'Trop de tentatives. Attendez ou demandez un nouveau code.';

  static String get assignmentInactive => isArabic
      ? 'هذا التعيين لم يعد نشطًا.'
      : 'Cette affectation n’est plus active.';

  static String get invalidState => isArabic
      ? 'هذا الإجراء لم يعد متاحًا.'
      : 'Cette action n’est plus disponible.';

  static String get handoffInvalidState => isArabic
      ? 'التسليم لم يعد متاحًا. حدّث الطلبية.'
      : 'La remise n’est plus disponible. Actualisez la course.';

  static String get assignmentConflict => isArabic
      ? 'تغيّر التعيين. حدّث الطلبية.'
      : 'Cette affectation a changé. Actualisez la course.';

  static String get homeTitle => isArabic ? 'التوفر' : 'Disponibilité';

  static String get homeLoading =>
      isArabic ? 'جاري تحميل حالة التوفر…' : 'Chargement de la disponibilité…';

  static String get availabilityOnline => isArabic ? 'متصل' : 'En ligne';

  static String get availabilityOffline => isArabic ? 'غير متصل' : 'Hors ligne';

  static String get availabilitySuspended => isArabic ? 'موقوف' : 'Suspendu';

  static String get availabilityOfflineAfterCurrent => isArabic
      ? 'غير متصل بعد التوصيل الحالي'
      : 'Hors ligne après la course en cours';

  static String get goOnline => isArabic ? 'الاتصال' : 'Passer en ligne';

  static String get goOffline => isArabic ? 'قطع الاتصال' : 'Passer hors ligne';

  static String get goingOnline =>
      isArabic ? 'جاري الاتصال…' : 'Mise en ligne…';

  static String get goingOffline =>
      isArabic ? 'جاري قطع الاتصال…' : 'Mise hors ligne…';

  static String get waitingForOffer =>
      isArabic ? 'في انتظار عرض توصيل…' : 'En attente d’une offre…';

  static String get waitingForOfferHint => isArabic
      ? 'ابقَ متصلًا مع موقع مفعّل لاستلام العروض.'
      : 'Restez en ligne avec la localisation active pour recevoir des offres.';

  static String get offerTitle => isArabic ? 'عرض توصيل' : 'Offre de livraison';

  static String get offerCountdownLabel =>
      isArabic ? 'ينتهي خلال' : 'Expire dans';

  static String get offerExpired =>
      isArabic ? 'انتهت صلاحية العرض.' : 'Cette offre a expiré.';

  static String get offerAccept => isArabic ? 'قبول' : 'Accepter';

  static String get offerReject => isArabic ? 'رفض' : 'Refuser';

  static String get offerAccepting =>
      isArabic ? 'جاري القبول…' : 'Acceptation…';

  static String get offerRejecting => isArabic ? 'جاري الرفض…' : 'Refus…';

  static String get offerPickupLabel =>
      isArabic ? 'الاستلام من' : 'Retrait chez';

  static String get offerRemunerationLabel =>
      isArabic ? 'أجر التوصيل' : 'Rémunération';

  static String get offerPickupDistanceLabel =>
      isArabic ? 'المسافة إلى الاستلام' : 'Distance retrait';

  static String get offerDeliveryDistanceLabel =>
      isArabic ? 'المسافة إلى التسليم' : 'Distance livraison';

  static String get offerOrderRefLabel => isArabic ? 'المرجع' : 'Référence';

  static String get openCurrentDelivery =>
      isArabic ? 'فتح الطلب الحالي' : 'Ouvrir la course en cours';

  static String get activeDeliveryBanner => isArabic
      ? 'لديك طلب نشط. أكمل التسليم قبل عروض جديدة.'
      : 'Vous avez une course active. Terminez-la avant de nouvelles offres.';

  static String get locationServicesDisabled => isArabic
      ? 'فعّل خدمات الموقع على الجهاز.'
      : 'Activez les services de localisation sur l’appareil.';

  static String get locationPermissionDenied => isArabic
      ? 'إذن الموقع مطلوب لاستلام العروض وقبولها.'
      : 'L’autorisation de localisation est requise pour recevoir et accepter des offres.';

  static String get locationPermissionDeniedForever => isArabic
      ? 'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات النظام.'
      : 'Localisation refusée définitivement. Activez-la dans les réglages système.';

  static String get locationUnavailable => isArabic
      ? 'تعذّر الحصول على الموقع.'
      : 'Impossible d’obtenir la position.';

  static String get locationTimeout => isArabic
      ? 'انتهت مهلة الحصول على الموقع.'
      : 'Délai dépassé pour obtenir la position.';

  static String get locationPublishing =>
      isArabic ? 'إرسال الموقع…' : 'Envoi de la position…';

  static String get driverNotApproved => isArabic
      ? 'حسابك غير معتمد بعد. أكمل التحقق أولًا.'
      : 'Votre compte n’est pas encore approuvé. Terminez la vérification.';

  static String get driverNotOperational => isArabic
      ? 'الملف غير جاهز للتشغيل (وثائق أو مركبة ناقصة).'
      : 'Profil non opérationnel (documents ou véhicule incomplets).';

  static String get driverAvailabilityInvalid => isArabic
      ? 'تعذّر تغيير حالة التوفر. حدّث ثم أعد المحاولة.'
      : 'Impossible de changer la disponibilité. Actualisez puis réessayez.';

  static String get offerTakenOrStale => isArabic
      ? 'لم يعد هذا العرض متاحًا.'
      : 'Cette offre n’est plus disponible.';

  static String get offerLocationRequired => isArabic
      ? 'يلزم موقع حديث لقبول العرض.'
      : 'Une position récente est requise pour accepter l’offre.';

  static String get offerLocationStale => isArabic
      ? 'موقعك قديم. أعد المحاولة بعد تحديث الموقع.'
      : 'Votre position est obsolète. Réessayez après actualisation.';

  static String get notMatchingEligible => isArabic
      ? 'لست مؤهلًا للمطابقة حاليًا.'
      : 'Vous n’êtes pas éligible au matching pour le moment.';

  static String get metersUnit => isArabic ? 'م' : 'm';

  static String locationErrorFor(String failureName) {
    switch (failureName) {
      case 'servicesDisabled':
        return locationServicesDisabled;
      case 'permissionDenied':
        return locationPermissionDenied;
      case 'permissionDeniedForever':
        return locationPermissionDeniedForever;
      case 'timeout':
        return locationTimeout;
      case 'unavailable':
      default:
        return locationUnavailable;
    }
  }

  static String availabilityStatusLabel(String? status) {
    switch (status) {
      case 'ONLINE':
        return availabilityOnline;
      case 'OFFLINE_AFTER_CURRENT_DELIVERY':
        return availabilityOfflineAfterCurrent;
      case 'SUSPENDED':
        return availabilitySuspended;
      case 'OFFLINE':
      default:
        return availabilityOffline;
    }
  }

  static String formatMinorUnits(String minor) {
    final value = int.tryParse(minor) ?? 0;
    final major = (value / 100).toStringAsFixed(value % 100 == 0 ? 0 : 2);
    return isArabic ? '$major د.ج' : '$major DA';
  }

  static String formatDistanceMeters(int meters) {
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return isArabic ? '$km كم' : '$km km';
    }
    return '$meters $metersUnit';
  }

  static String errorForCode(String? code) {
    switch (code) {
      case 'PICKUP_HANDOFF_CODE_INVALID':
        return codeInvalid;
      case 'PICKUP_HANDOFF_EXPIRED':
        return codeExpired;
      case 'PICKUP_HANDOFF_LOCKED':
      case 'PICKUP_HANDOFF_RATE_LIMITED':
        return codeLocked;
      case 'PICKUP_HANDOFF_ASSIGNMENT_CONFLICT':
        return assignmentConflict;
      case 'PICKUP_HANDOFF_INVALID_STATE':
      case 'PICKUP_HANDOFF_ALREADY_CONSUMED':
        return handoffInvalidState;
      case 'DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE':
        return assignmentInactive;
      case 'DRIVER_DELIVERY_INVALID_STATE':
      case 'DRIVER_DELIVERY_ACTION_NOT_ALLOWED':
        return invalidState;
      case 'DRIVER_DELIVERY_NOT_FOUND':
        return deliveryEmpty;
      case 'DRIVER_NOT_APPROVED':
        return driverNotApproved;
      case 'DRIVER_NOT_OPERATIONAL':
      case 'DRIVER_ONBOARDING_INCOMPLETE':
        return driverNotOperational;
      case 'DRIVER_AVAILABILITY_INVALID_TRANSITION':
        return driverAvailabilityInvalid;
      case 'DRIVER_PROFILE_NOT_FOUND':
        return noDriverProfile;
      case 'DRIVER_ASSIGNMENT_EXPIRED':
        return offerExpired;
      case 'DRIVER_ASSIGNMENT_INVALID_STATE':
      case 'DRIVER_ASSIGNMENT_NOT_FOUND':
      case 'DELIVERY_ALREADY_ASSIGNED':
      case 'DELIVERY_NOT_SEARCHING_DRIVER':
      case 'DRIVER_ALREADY_ASSIGNED':
        return offerTakenOrStale;
      case 'DRIVER_LOCATION_REQUIRED':
        return offerLocationRequired;
      case 'DRIVER_LOCATION_STALE':
        return offerLocationStale;
      case 'DRIVER_NOT_MATCHING_ELIGIBLE':
        return notMatchingEligible;
      case 'DRIVER_LOCATION_NOT_ALLOWED':
        return locationPermissionDenied;
      case 'NETWORK':
        return networkError;
      default:
        return unexpectedError;
    }
  }

  static String deliveryStatusLabel(String status) {
    if (isArabic) {
      switch (status) {
        case 'DRIVER_ASSIGNED':
          return 'تم التعيين';
        case 'TO_PICKUP':
          return 'في الطريق إلى التاجر';
        case 'AT_PICKUP':
          return 'وصل إلى التاجر';
        case 'PICKED_UP':
          return 'تم الاستلام';
        case 'IN_TRANSIT':
          return 'قيد التوصيل';
        case 'ARRIVED_CUSTOMER':
          return 'وصل إلى العميل';
        case 'DELIVERED':
          return 'تم التسليم';
        default:
          return status;
      }
    }
    switch (status) {
      case 'DRIVER_ASSIGNED':
        return 'Affectée';
      case 'TO_PICKUP':
        return 'En route vers le commerçant';
      case 'AT_PICKUP':
        return 'Arrivé chez le commerçant';
      case 'PICKED_UP':
        return 'Prise en charge';
      case 'IN_TRANSIT':
        return 'En livraison';
      case 'ARRIVED_CUSTOMER':
        return 'Arrivé chez le client';
      case 'DELIVERED':
        return 'Livrée';
      default:
        return status;
    }
  }

  /// Compatibility alias used by existing call sites / tests.
  static String deliveryStatusFr(String status) => deliveryStatusLabel(status);
}
