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

  static String get appName =>
      isArabic ? 'SpeedyGo سائق' : 'SpeedyGo Driver';

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

  static String get phoneInvalid => isArabic
      ? 'أدخل رقمًا صالحًا.'
      : 'Saisissez un numéro valide.';

  static String get otpTitle =>
      isArabic ? 'رمز التحقق' : 'Code de vérification';

  static String get otpHint =>
      isArabic ? 'الرمز المستلم عبر الرسالة' : 'Code reçu par SMS';

  static String get otpVerify => isArabic ? 'تأكيد' : 'Valider';

  static String get otpResend => isArabic ? 'إعادة إرسال الرمز' : 'Renvoyer le code';

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

  static String get languageSettingsTitle =>
      isArabic ? 'اللغة' : 'Langue';

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
