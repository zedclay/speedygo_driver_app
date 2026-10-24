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

  static String get splashTagline =>
      isArabic ? 'توصيل بسرعة. بكل ثقة.' : 'Livrez vite. En confiance.';

  // --- First-launch intro (product slides; not registration onboarding) ---
  static String get firstLaunchIntroSkip => isArabic ? 'تخطي' : 'Passer';

  static String get firstLaunchIntroNext => isArabic ? 'التالي' : 'Suivant';

  static String get firstLaunchIntroStart => isArabic ? 'ابدأ' : 'Commencer';

  static String get firstLaunchIntroPage1Title =>
      isArabic ? 'استلم طلبات التوصيل' : 'Recevez des courses';

  static String get firstLaunchIntroPage1Body => isArabic
      ? 'فعّل وضع الاتصال واستلم عروض توصيل مناسبة لمنطقتك.'
      : 'Passez en ligne et recevez des offres adaptées à votre zone.';

  static String get firstLaunchIntroPage2Title =>
      isArabic ? 'وصّل بكل سهولة' : 'Livrez en toute simplicité';

  static String get firstLaunchIntroPage2Body => isArabic
      ? 'تابع كل مرحلة، من استلام الطلب لدى التاجر حتى تسليمه إلى العميل.'
      : 'Suivez chaque étape, du retrait chez le marchand jusqu’au client.';

  static String get firstLaunchIntroPage3Title =>
      isArabic ? 'تحكّم في أرباحك' : 'Gardez le contrôle de vos gains';

  static String get firstLaunchIntroPage3Body => isArabic
      ? 'راجع عمليات التوصيل وتابع أرباحك بكل وضوح.'
      : 'Consultez vos livraisons et suivez vos revenus en toute clarté.';

  static String firstLaunchIntroPageSemantics(int page, int total) =>
      isArabic ? 'صفحة $page من $total' : 'Page $page sur $total';

  static String get networkError => isArabic
      ? 'تعذّر الاتصال. أعد المحاولة.'
      : 'Connexion impossible. Réessayez.';

  static String get unexpectedError => isArabic
      ? 'حدث خطأ. أعد المحاولة.'
      : 'Une erreur est survenue. Réessayez.';

  static String get sessionExpired => isArabic
      ? 'انتهت الجلسة. سجّل الدخول مجددًا.'
      : 'Session expirée. Reconnectez-vous.';

  static String get restoreOffline => isArabic
      ? 'تعذّر استعادة الجلسة. تحقق من الاتصال ثم أعد المحاولة.'
      : 'Impossible de rétablir la session. Vérifiez la connexion puis réessayez.';

  static String get restoreRetry => isArabic ? 'إعادة المحاولة' : 'Réessayer';

  static String get restoreOtherAccount =>
      isArabic ? 'استخدام رقم آخر' : 'Utiliser un autre numéro';

  static String get restorePermissionDenied => isArabic
      ? 'هذا الحساب لا يمكنه فتح تطبيق السائق. لم تُحذف بيانات الدخول.'
      : 'Ce compte ne peut pas ouvrir l’app chauffeur. Vos identifiants sont conservés.';

  static String get phoneTitle =>
      isArabic ? 'أدخل رقم هاتفك' : 'Entrez votre numéro de téléphone';

  static String get phoneSubtitle => isArabic
      ? 'سنرسل إليك رمز تحقق عبر رسالة قصيرة.'
      : 'Nous vous enverrons un code de vérification par SMS.';

  static String get phoneHint => '555 12 34 56';

  static String get phonePrefix => '+213';

  static String get phoneSmsNote => isArabic
      ? 'قد تُطبَّق رسوم الرسائل القصيرة المعتادة.'
      : 'Les frais de SMS standard peuvent s’appliquer.';

  static String get phoneContinue => isArabic ? 'متابعة' : 'Continuer';

  static String get continueLabel => phoneContinue;

  static String get phoneInvalid => isArabic
      ? 'أدخل رقمًا جزائريًا صالحًا.'
      : 'Saisissez un numéro algérien valide.';

  static String get needHelp =>
      isArabic ? 'هل تحتاج مساعدة؟' : 'Besoin d’aide ?';

  static String get helpUnavailable => isArabic
      ? 'ستتوفر المساعدة في إصدار لاحق.'
      : 'L’assistance sera disponible dans une prochaine version.';

  static String get otpTitle =>
      isArabic ? 'التحقق من الرمز' : 'Vérification du code';

  static String get otpHint =>
      isArabic ? 'الرمز المستلم عبر الرسالة' : 'Code reçu par SMS';

  static String get otpVerify => isArabic ? 'تحقق' : 'Vérifier';

  static String get verify => otpVerify;

  static String get editNumber => isArabic ? 'تعديل' : 'Modifier';

  static String get otpResend =>
      isArabic ? 'إعادة إرسال الرمز' : 'Renvoyer le code';

  static String get resend => otpResend;

  static String resendIn(String clock) => isArabic
      ? 'إعادة إرسال الرمز خلال $clock'
      : 'Renvoyer le code dans $clock';

  static String get otpCooldownHint => isArabic
      ? 'يُرجى الانتظار قبل إعادة إرسال رمز'
      : 'Patientez avant de renvoyer un code';

  static String otpSentTo(String masked) =>
      isArabic ? 'تم إرسال الرمز إلى $masked' : 'Code envoyé au $masked';

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

  static String get logoutScreenTitle =>
      isArabic ? 'تسجيل الخروج' : 'Déconnexion';

  static String get logoutConfirmTitle =>
      isArabic ? 'تسجيل الخروج؟' : 'Se déconnecter ?';

  static String get logoutConfirmBody => isArabic
      ? 'ستحتاج إلى إعادة تسجيل الدخول للمتابعة.'
      : 'Vous devrez vous reconnecter pour continuer.';

  static String get logoutAttentionLabel => isArabic ? 'تنبيه' : 'Attention';

  static String get logoutConfirmWarning => isArabic
      ? 'لن تتلقى طلبات توصيل جديدة حتى تسجّل الدخول مجددًا.'
      : 'Vous ne recevrez plus de nouvelles demandes de livraison jusqu’à votre prochaine connexion.';

  static String get logoutConfirmWarningFull => isArabic
      ? 'سيتم تسجيل خروجك. لن تتلقى طلبات توصيل جديدة حتى تسجّل الدخول مجددًا.'
      : 'Vous allez être déconnecté. Vous ne recevrez plus de nouvelles demandes de livraison jusqu’à votre prochaine connexion.';

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

  static String get availabilityOnline =>
      isArabic ? 'متاح للطلبات' : 'En ligne';

  static String get availabilityOffline =>
      isArabic ? 'غير متاح للطلبات' : 'Hors ligne';

  static String get availabilitySuspended => isArabic ? 'موقوف' : 'Suspendu';

  static String get availabilityOfflineAfterCurrent => isArabic
      ? 'غير متاح بعد التوصيل الحالي'
      : 'Hors ligne après la course en cours';

  static String get goOnline =>
      isArabic ? 'بدء استقبال الطلبات' : 'Passer en ligne';

  static String get goOffline =>
      isArabic ? 'إيقاف استقبال الطلبات' : 'Passer hors ligne';

  static String get goingOnline =>
      isArabic ? 'جاري بدء استقبال الطلبات…' : 'Mise en ligne…';

  static String get goingOffline =>
      isArabic ? 'جاري إيقاف استقبال الطلبات…' : 'Mise hors ligne…';

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
      ? 'خدمات الموقع على الجهاز متوقفة. فعّلها ثم أعد المحاولة.'
      : 'Les services de localisation de l’appareil sont désactivés. Activez-les puis réessayez.';

  static String get locationPermissionDenied => isArabic
      ? 'إذن «أثناء الاستخدام» مطلوب لاستلام العروض وقبولها. اضغط للتفعيل.'
      : 'L’autorisation « Lorsque l’app est active » est requise pour recevoir et accepter des offres. Appuyez pour l’activer.';

  static String get locationPermissionDeniedForever => isArabic
      ? 'إذن الموقع مرفوض. افتح إعدادات النظام وفعّل الموقع لهذا التطبيق.'
      : 'Localisation refusée. Ouvrez les réglages système et autorisez la localisation pour cette app.';

  static String get locationUnavailable => isArabic
      ? 'تعذّر الحصول على موضع GPS. تحقق من الإشارة ثم أعد المحاولة.'
      : 'Impossible d’obtenir une position GPS. Vérifiez le signal puis réessayez.';

  static String get locationTimeout => isArabic
      ? 'انتهت مهلة الحصول على الموقع. تحقق من GPS وحاولة مرة أخرى.'
      : 'Délai dépassé pour obtenir la position. Vérifiez le GPS puis réessayez.';

  static String get locationPublishing =>
      isArabic ? 'إرسال الموقع…' : 'Envoi de la position…';

  static String get locationActive =>
      isArabic ? 'الموقع نشط' : 'Localisation active';

  static String get locationNotChecked =>
      isArabic ? 'الموقع غير مُتحقق منه بعد' : 'Localisation non vérifiée';

  static String get locationPublishFailed => isArabic
      ? 'تعذّر إرسال موقعك إلى SpeedyGo. تحقق من الاتصال ثم أعد المحاولة.'
      : 'Impossible d’envoyer votre position à SpeedyGo. Vérifiez la connexion puis réessayez.';

  static String get locationStoreUnavailable => isArabic
      ? 'خدمة الموقع غير متاحة مؤقتًا. أعد المحاولة بعد لحظات.'
      : 'Le service de localisation est temporairement indisponible. Réessayez dans un instant.';

  static String get locationRateLimited => isArabic
      ? 'تحديثات الموقع كثيرة جدًا. انتظر لحظة ثم أعد المحاولة.'
      : 'Trop de mises à jour de position. Patientez un instant puis réessayez.';

  static String get locationEnableAction =>
      isArabic ? 'تفعيل الموقع' : 'Activer la localisation';

  static String get locationOpenSettingsAction =>
      isArabic ? 'فتح الإعدادات' : 'Ouvrir les réglages';

  static String get locationOpenLocationSettingsAction =>
      isArabic ? 'تفعيل خدمات الموقع' : 'Activer les services de localisation';

  static String get locationRetryAction =>
      isArabic ? 'إعادة المحاولة' : 'Réessayer';

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

  // ---------------------------------------------------------------------------
  // Driver Stitch UI v1 — shell, lifecycle, history, earnings, profile,
  // onboarding, support, notifications, blocked states.
  // ---------------------------------------------------------------------------

  static String _t(String fr, String ar) => isArabic ? ar : fr;

  // Shell
  static String get navOrders => _t('Commandes', 'الطلبات');
  static String get navHistory => _t('Historique', 'السجل');
  static String get navEarnings => _t('Gains', 'الأرباح');
  static String get navProfile => _t('Profil', 'الملف');
  static String get navSupport => _t('Aide et support', 'المساعدة والدعم');
  static String get navVehicle => _t('Mon véhicule', 'مركبتي');
  static String get navDocuments => _t('Mes documents', 'مستنداتي');
  static String get navRatings => _t('Mes évaluations', 'تقييماتي');
  static String get navSettings => _t('Paramètres', 'الإعدادات');

  static String get openMenu => _t('Ouvrir le menu', 'فتح القائمة');
  static String get closeMenu => _t('Fermer le menu', 'إغلاق القائمة');
  static String get accountVerified => _t('Compte vérifié', 'حساب موثّق');

  static String get yourStatusLabel =>
      _t('VOTRE STATUT', 'حالتك');

  static String get goOnlineHint =>
      _t('Passez en ligne pour recevoir des commandes.',
          'انتقل إلى المتاح لاستلام الطلبات.');

  static String get yourActivityLabel =>
      _t('Votre activité', 'نشاطك');

  static String get accountTotalsNote =>
      _t('Cumul du compte', 'إجمالي الحساب');

  static String get zoneCheckCta => _t('Vérifier', 'تحقق');

  static String homeGreeting(String name) {
    final n = name.trim().isEmpty
        ? profileNoName
        : name.trim().split(' ').first;
    return isArabic ? 'مرحبًا، $n' : 'Bonjour, $n';
  }

  static String homeDateLine(String formatted) => formatted;

  static String get searchingDeliveries =>
      _t('Recherche de livraisons…', 'جاري البحث عن توصيلات…');

  static String get offlineNoOrders => _t(
    'Vous ne recevez actuellement aucune commande.',
    'لا تستلم أي طلبات حاليًا.',
  );

  static String get slideToGoOffline => _t(
    'Glisser pour passer hors ligne',
    'اسحب لإيقاف استقبال الطلبات',
  );

  static String get slideToGoOnline => _t(
    'Glisser pour passer en ligne',
    'اسحب لبدء استقبال الطلبات',
  );

  static String get homeSupportTitle =>
      _t('Besoin d’aide ?', 'هل تحتاج مساعدة؟');

  static String get homeSupportBody => _t(
    'Un problème avec une commande, votre compte ou vos documents ?',
    'مشكلة في طلب أو حسابك أو مستنداتك؟',
  );

  static String get homeSupportCta =>
      _t('Contacter le support', 'التواصل مع الدعم');

  static String get homeActiveTaskSection => _t('Tâche en cours', 'مهمة جارية');

  static String get homeResumeDelivery =>
      _t('Reprendre la course', 'استئناف التوصيل');

  static String get homeTotalsSection => _t('Aujourd\'hui', 'اليوم');

  static String get homeTotalsNote => _t(
    'Cumul compte (période « aujourd’hui » non fournie par l’API).',
    'إجمالي الحساب (لا تتوفر فترة «اليوم» من الواجهة).',
  );

  static String get homeCollectionsLabel => _t('Encaissements', 'التحصيلات');

  static String get homeCompletedRidesLabel =>
      _t('Courses terminées', 'رحلات مكتملة');

  static String get homeMetricUnavailable => '—';

  static String get zoneUnavailable =>
      _t('Zone non disponible', 'المنطقة غير متاحة');

  static String locationStatusLine(String statusName) {
    switch (statusName) {
      case 'ready':
        return locationActive;
      case 'publishing':
        return locationPublishing;
      case 'servicesDisabled':
        return locationServicesDisabled;
      case 'permissionDenied':
        return locationPermissionDenied;
      case 'permissionDeniedForever':
        return locationPermissionDeniedForever;
      case 'timeout':
        return locationTimeout;
      case 'unavailable':
      case 'error':
        return locationUnavailable;
      case 'unknown':
      default:
        return locationNotChecked;
    }
  }
  static String get notificationsTooltip => _t('Notifications', 'الإشعارات');
  static String get profileTooltip => _t('Mon profil', 'ملفي');
  static String get close => _t('Fermer', 'إغلاق');
  static String get save => _t('Enregistrer', 'حفظ');
  static String get saving => _t('Enregistrement…', 'جاري الحفظ…');
  static String get back => _t('Retour', 'رجوع');
  static String get loadMore => _t('Charger plus', 'عرض المزيد');
  static String get loading => _t('Chargement…', 'جاري التحميل…');

  // Delivery lifecycle
  static String get deliveredSuccess =>
      _t('Livraison terminée.', 'تم إنهاء التوصيل.');
  static String get deliveredBody => _t(
    'Course livrée. Votre gain est enregistré par le serveur.',
    'تم التسليم. يسجّل الخادم أرباحك.',
  );
  static String get backToOrders =>
      _t('Retour aux commandes', 'العودة إلى الطلبات');
  static String get backToHome =>
      _t('Retour à l\'accueil', 'العودة إلى الرئيسية');
  static String get deliveredOrderLabel => _t('N° de commande', 'رقم الطلب');
  static String get deliveryPrivacyNote => _t(
    'Les détails du client final et l’adresse de livraison sont révélés après la confirmation du retrait.',
    'تظهر تفاصيل العميل وعنوان التسليم بعد تأكيد الاستلام.',
  );
  static String get navPickupTitle =>
      _t('Navigation vers le commerçant', 'التنقل إلى التاجر');
  static String get navDropoffTitle =>
      _t('Navigation vers le client', 'التنقل إلى العميل');
  static String get dropoffBuildingLabel => _t('Bâtiment', 'المبنى');
  static String get dropoffFloorLabel => _t('Étage', 'الطابق');
  static String get dropoffEntranceLabel => _t('Entrée', 'المدخل');
  static String get dropoffLandmarkLabel =>
      _t('Point de repère', 'علامة مميّزة');
  static String get dropoffInstructionsTitle =>
      _t('Instructions de livraison', 'تعليمات التسليم');
  static String get navUnavailable => _t(
    'Navigation indisponible : aucune adresse ni application de cartes n’est fournie par le serveur pour cette course.',
    'التنقل غير متاح: لا يوفّر الخادم عنوانًا ولا تطبيق خرائط لهذا الطلب.',
  );
  static String get navPositionReady => _t(
    'Position de livraison disponible',
    'موقع التسليم متاح',
  );
  static String get navCopyHint => _t(
    'Copiez l’adresse puis ouvrez-la dans l’application de cartes de votre choix.',
    'انسخ العنوان ثم افتحه في تطبيق الخرائط الذي تفضّله.',
  );
  static String get navCopy => _t('Copier', 'نسخ');
  static String get navCopied => _t('Copié.', 'تم النسخ.');
  static String get navDistance => _t('Distance', 'المسافة');
  static String get navExternal => _t('Nav. externe', 'تنقل خارجي');
  static String get navContact => _t('Contacter', 'اتصال');
  static String get deliveryInProgressBadge => _t('En cours', 'جارية');
  static String get deliveryMapYou => _t('Vous', 'أنت');
  static String get deliveryMapMerchant => _t('Marchand', 'التاجر');
  static String get deliveryMapCustomer => _t('Client', 'العميل');
  static String get deliveryWaitingPrepTitle =>
      _t('En attente de préparation', 'في انتظار التحضير');
  static String get deliveryWaitingPrepBody => _t(
    'Le commerçant prépare encore la commande. Restez disponible sur place.',
    'لا يزال التاجر يحضّر الطلب. ابقَ في المكان.',
  );
  static String get deliveryOrderRefPrefix => _t('Réf.', 'مرجع');
  static String get deliveryContactMerchant =>
      _t('Contacter le marchand', 'الاتصال بالتاجر');
  static String get deliveryContactCustomer =>
      _t('Contacter le client', 'الاتصال بالعميل');
  static String get deliveryReportProblem =>
      _t('Signaler un problème', 'الإبلاغ عن مشكلة');
  static String get blockedActionUnavailable =>
      _t('Indisponible — aucun contrat serveur', 'غير متاح — لا عقد خادم');
  static String get blockedReturnToDelivery =>
      _t('Retour à la course', 'العودة إلى الطلب');
  static String get profileSectionManage => _t('Gestion', 'الإدارة');
  static String get profileSectionPreferences => _t('Préférences', 'التفضيلات');
  static String get historyRefLabel => _t('Réf', 'مرجع');
  static String get earningsCodReconciliationTitle =>
      _t('Réconciliation de caisse', 'تسوية الصندوق');
  static String get earningsOperationalTotals =>
      _t('Totaux opérationnels', 'المجاميع التشغيلية');

  static String deliveryTaskPhase(String status) {
    switch (status) {
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'ARRIVED_CUSTOMER':
        return _t('Livraison', 'توصيل');
      default:
        return _t('Récupération', 'استلام');
    }
  }

  static bool deliveryWaitingForPrep(String status, String fulfillment) =>
      status == 'AT_PICKUP' && fulfillment.isNotEmpty && fulfillment != 'READY';

  static String deliveryActionLabel(String key) {
    switch (key) {
      case 'start-to-pickup':
        return _t('Partir vers le commerçant', 'التوجه إلى التاجر');
      case 'arrive-pickup':
        return _t('Je suis arrivé chez le commerçant', 'وصلت إلى التاجر');
      case 'confirm-pickup':
        return confirmPickup;
      case 'start-delivery':
        return _t('Démarrer la livraison', 'بدء التوصيل');
      case 'arrive-customer':
        return _t('Je suis arrivé chez le client', 'وصلت إلى العميل');
      case 'complete-delivery':
        return _t('Terminer la livraison', 'إنهاء التوصيل');
      default:
        return key;
    }
  }

  static String deliveryStepHint(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED':
        return _t(
          'Commencez la course dès que vous êtes prêt.',
          'ابدأ الطلب عندما تكون جاهزًا.',
        );
      case 'TO_PICKUP':
        return _t(
          'Rendez-vous chez le commerçant. Votre position sera envoyée à l’arrivée.',
          'توجّه إلى التاجر. سيُرسل موقعك عند الوصول.',
        );
      case 'AT_PICKUP':
        return _t(
          'Récupérez la commande avec le code du commerçant.',
          'استلم الطلب باستخدام رمز التاجر.',
        );
      case 'PICKED_UP':
        return _t(
          'Commande récupérée. Démarrez la livraison.',
          'تم استلام الطلب. ابدأ التوصيل.',
        );
      case 'IN_TRANSIT':
        return _t(
          'En route vers le client. Votre position sera envoyée à l’arrivée.',
          'في الطريق إلى العميل. سيُرسل موقعك عند الوصول.',
        );
      case 'ARRIVED_CUSTOMER':
        return _t(
          'Remettez la commande, encaissez si paiement à la livraison, puis terminez.',
          'سلّم الطلب، حصّل المبلغ عند الدفع عند الاستلام، ثم أنهِ الطلب.',
        );
      case 'DELIVERED':
        return _t('Course terminée.', 'اكتمل الطلب.');
      default:
        return '';
    }
  }

  static String get codTitle =>
      _t('Paiement à la livraison (COD)', 'الدفع عند الاستلام');
  static String get codIntro => _t(
    'Si la commande est payée en espèces, saisissez le montant exact encaissé auprès du client.',
    'إذا كان الدفع نقدًا، أدخل المبلغ الدقيق الذي حصّلته من العميل.',
  );
  static String get codAmountLabel => _t(
    'Montant encaissé (DA)',
    'المبلغ المقبوض (دج)',
  );
  static String get codAmountHelp => _t(
    'Saisissez le montant exact en dinars (jusqu’à 2 décimales).',
    'أدخل المبلغ الدقيق بالدينار (حتى منزلتين عشريتين).',
  );
  static String get codAmountInvalid => _t(
    'Montant invalide. Utilisez un nombre avec au plus 2 décimales.',
    'مبلغ غير صالح. استخدم رقمًا بمنزلتين عشريتين كحد أقصى.',
  );
  static String get codExpectedLabel => _t('Montant attendu', 'المبلغ المتوقع');
  static String codExpectedAmount(String formattedDzd) => isArabic
      ? '$codExpectedLabel : $formattedDzd'
      : '$codExpectedLabel : $formattedDzd';
  static String get codCollect =>
      _t('Enregistrer l’encaissement', 'تسجيل التحصيل');
  static String get codCollectedBadge => _t('Encaissé', 'تم التحصيل');
  static String get codCollectedSuccess =>
      _t('Encaissement enregistré.', 'تم تسجيل التحصيل.');
  static String get deliveryHelpTitle => _t('Besoin d’aide ?', 'تحتاج مساعدة؟');
  static String get contactUnavailableTitle =>
      _t('Contacter le commerçant ou le client', 'التواصل مع التاجر أو العميل');
  static String get failureReportTitle =>
      _t('Signaler un problème de livraison', 'الإبلاغ عن مشكلة في التوصيل');

  // Blocked / honest unavailable states
  static String get blockedTitle => _t('Pas encore disponible', 'غير متاح بعد');
  static String blockedHeading(String kind) {
    switch (kind) {
      case 'contact':
        return contactUnavailableTitle;
      case 'failure-report':
        return failureReportTitle;
      case 'delivery-pin':
        return _t('Code de livraison client', 'رمز التسليم للعميل');
      case 'maps':
        return _t('Navigation cartographique', 'التنقل بالخرائط');
      case 'notification-prefs':
        return _t('Préférences de notification', 'تفضيلات الإشعارات');
      default:
        return blockedTitle;
    }
  }

  static String blockedBody(String kind) {
    switch (kind) {
      case 'contact':
        return _t(
          'Aucun service de mise en relation masquée n’est disponible dans l’API. Vos numéros ne sont pas partagés. Utilisez le support si besoin.',
          'لا توجد خدمة اتصال مُخفى الرقم في الواجهة البرمجية حاليًا. لا تتم مشاركة الأرقام. استخدم الدعم عند الحاجة.',
        );
      case 'failure-report':
        return _t(
          'Le signalement d’échec de livraison n’a pas encore de contrat serveur. Contactez le support depuis votre profil.',
          'لا يوجد عقد خادم للإبلاغ عن فشل التوصيل بعد. تواصل مع الدعم من ملفك.',
        );
      case 'delivery-pin':
        return _t(
          'La validation par code client n’est pas prévue dans cette version : la livraison est terminée sans preuve.',
          'التحقق برمز العميل غير مدعوم في هذه النسخة: يُنهى التوصيل دون إثبات.',
        );
      case 'maps':
        return _t(
          'Aucune carte intégrée ni fournisseur de navigation n’est configuré. Copiez l’adresse dans votre application de cartes.',
          'لا توجد خريطة مدمجة ولا مزوّد تنقل مُعدّ. انسخ العنوان إلى تطبيق الخرائط لديك.',
        );
      case 'notification-prefs':
        return _t(
          'Les préférences de notification ne sont pas encore exposées par le serveur. Les notifications in-app restent disponibles.',
          'لا يتيح الخادم تفضيلات الإشعارات بعد. تبقى الإشعارات داخل التطبيق متاحة.',
        );
      default:
        return _t('Fonction indisponible.', 'الميزة غير متاحة.');
    }
  }

  // History
  static String get historyTitle => _t('Historique', 'السجل');
  static String get historyEmpty =>
      _t('Aucune livraison terminée.', 'لا توجد توصيلات مكتملة.');
  static String get historyEmptyHint => _t(
    'Vos courses livrées apparaîtront ici.',
    'ستظهر هنا الطلبات التي أنجزتها.',
  );
  static String get historyDetailTitle =>
      _t('Détail de la livraison', 'تفاصيل التوصيل');
  static String get historyMerchant => _t('Commerçant', 'التاجر');
  static String get historyBranch => _t('Succursale', 'الفرع');
  static String get historyPaymentMethod => _t('Paiement', 'الدفع');
  static String get historyDeliveredAt => _t('Livrée le', 'تاريخ التسليم');
  static String get historyPickedUpAt => _t('Prise en charge', 'وقت الاستلام');
  static String get historyArrivedAt =>
      _t('Arrivée chez le client', 'الوصول إلى العميل');
  static String get historyEarning => _t('Gain reconnu', 'الأرباح المعترف بها');
  static String get historyEarningNote => _t(
    'Gain reconnu pour cette course. Ce n’est pas un paiement versé.',
    'ربح معترف به لهذا الطلب. ليس دفعة مدفوعة.',
  );

  static String paymentMethodLabel(String? method) {
    switch (method) {
      case 'COD':
      case 'CASH_ON_DELIVERY':
        return _t('Paiement à la livraison', 'الدفع عند الاستلام');
      case null:
      case '':
        return '—';
      default:
        return _t('Paiement électronique', 'دفع إلكتروني');
    }
  }

  // Earnings & COD
  static String get earningsTitle => _t('Gains', 'الأرباح');
  static String get earningsTotal => _t('Total gagné', 'إجمالي الأرباح');
  static String get earningsUnpaid =>
      _t('Gains non versés', 'أرباح غير مدفوعة');
  static String get earningsCount =>
      _t('Courses rémunérées', 'طلبات مدفوعة الأجر');
  static String get earningsListTitle =>
      _t('Détail des gains', 'تفاصيل الأرباح');
  static String get earningsEmpty =>
      _t('Aucun gain enregistré.', 'لا توجد أرباح مسجّلة.');
  static String get earningsNote => _t(
    'Les gains ne sont pas un solde retirable et ne comprennent pas les espèces COD encaissées.',
    'الأرباح ليست رصيدًا قابلًا للسحب ولا تشمل النقد المحصّل عند الاستلام.',
  );
  static String get codSectionTitle =>
      _t('Espèces COD à remettre', 'نقد الدفع عند الاستلام المستحق');
  static String get codOutstanding =>
      _t('Espèces à remettre', 'نقد مستحق التسليم');
  static String get codCollectedTotal => _t('Total encaissé', 'إجمالي المحصّل');
  static String get codConfirmedAllocated =>
      _t('Remises confirmées', 'تسليمات مؤكدة');
  static String get codOpenDeclared =>
      _t('Déclarations en attente', 'إقرارات قيد الانتظار');
  static String get codRemitTitle =>
      _t('Déclarer une remise', 'إقرار تسليم نقد');
  static String get codRemitAmountLabel =>
      _t('Montant remis (DA)', 'المبلغ المسلّم (دج)');
  static String get codRemitHelp => _t(
    'Saisissez le montant exact en dinars (jusqu’à 2 décimales). La déclaration ne réduit pas votre solde tant que SpeedyGo ne l’a pas confirmée.',
    'أدخل المبلغ الدقيق بالدينار (حتى منزلتين عشريتين). لا يخفض الإقرار رصيدك حتى تؤكده SpeedyGo.',
  );
  static String get codRemitSubmit => _t('Déclarer', 'إقرار');
  static String get codRemitSuccess =>
      _t('Remise déclarée.', 'تم إقرار التسليم.');

  // Profile
  static String get profileTitle => _t('Mon profil', 'ملفي');

  static String get profileSubtitle =>
      _t('Vos informations et préférences', 'معلوماتك وتفضيلاتك');

  static String get profileSectionInfo =>
      _t('Mes informations', 'معلوماتي');

  static String get profileSectionAccount =>
      _t('Mon compte', 'حسابي');

  static String get offerPrivacyDelivery => _t(
    'Adresse exacte après acceptation',
    'العنوان الدقيق بعد القبول',
  );

  static String get offerItineraryTitle =>
      _t('Itinéraire de la course', 'مسار الرحلة');

  static String get offerAcceptCta =>
      _t('Accepter la course', 'قبول الرحلة');
  static String get profileVerification => _t('Vérification', 'التحقق');
  static String get profileMenuVehicle => _t('Véhicule', 'المركبة');
  static String get profileMenuDocuments => _t('Documents', 'المستندات');
  static String get profileMenuRatings => _t('Évaluations', 'التقييمات');
  static String get profileMenuSettings => _t('Réglages', 'الإعدادات');
  static String get profileMenuSupport => _t('Support', 'الدعم');
  static String get profileMenuOnboarding =>
      _t('Compléter mon dossier', 'استكمال ملفي');
  static String get profileNoName => _t('Livreur SpeedyGo', 'سائق SpeedyGo');

  static String verificationStatusLabel(String? status) {
    switch (status) {
      case 'APPROVED':
        return _t('Approuvé', 'معتمد');
      case 'PENDING_REVIEW':
        return _t('En cours de revue', 'قيد المراجعة');
      case 'REJECTED':
        return _t('À corriger', 'يحتاج تصحيحًا');
      case 'SUSPENDED':
        return _t('Suspendu', 'موقوف');
      case 'UNVERIFIED':
      default:
        return _t('Non vérifié', 'غير موثّق');
    }
  }

  static String get vehicleTitle => _t('Véhicule', 'المركبة');
  static String get vehicleNone =>
      _t('Aucun véhicule actif.', 'لا توجد مركبة نشطة.');
  static String get vehicleType => _t('Type', 'النوع');
  static String get vehiclePlate => _t('Plaque', 'رقم اللوحة');
  static String get vehicleModel => _t('Modèle', 'الطراز');
  static String get vehicleColor =>
      _t('Couleur (optionnel)', 'اللون (اختياري)');
  static String get vehicleSave => _t('Enregistrer le véhicule', 'حفظ المركبة');
  static String get vehicleSaved =>
      _t('Véhicule enregistré.', 'تم حفظ المركبة.');
  static String get vehicleApprovalLabel =>
      _t('Statut d\'approbation', 'حالة الاعتماد');
  static String get vehicleRegisteredDriver =>
      _t('Conducteur enregistré', 'السائق المسجّل');
  static String get vehicleChangeTitle =>
      _t('Changement de véhicule', 'تغيير المركبة');
  static String get vehicleChangeBody => _t(
    'Toute modification des informations de votre véhicule nécessite un examen administratif pour garantir la conformité.',
    'يتطلب أي تعديل على معلومات مركبتك مراجعة إدارية لضمان المطابقة.',
  );
  static String get vehicleLockedNote => _t(
    'Le véhicule ne peut être modifié que tant que le dossier n’est pas en revue ou approuvé.',
    'لا يمكن تعديل المركبة إلا قبل المراجعة أو الاعتماد.',
  );
  static String vehicleTypeLabel(String type) {
    switch (type) {
      case 'MOTORCYCLE':
        return _t('Moto', 'دراجة نارية');
      case 'SCOOTER':
        return _t('Scooter', 'سكوتر');
      case 'CAR':
        return _t('Voiture', 'سيارة');
      default:
        return type;
    }
  }

  static String get documentsTitle => _t('Documents', 'المستندات');
  static String get docIdentity => _t('Pièce d’identité', 'وثيقة الهوية');
  static String get docLicense => _t('Permis de conduire', 'رخصة القيادة');
  static String get docPresent => _t('Enregistré', 'مسجّل');
  static String get docMissing => _t('Manquant', 'مفقود');
  static String get docExpiry => _t('Expire le', 'تنتهي في');
  static String get docLockedNote => _t(
    'Les documents sont verrouillés pendant la revue et après approbation.',
    'المستندات مقفلة أثناء المراجعة وبعد الاعتماد.',
  );
  static String get docNeverShown => _t(
    'Les fichiers envoyés restent privés et ne sont jamais réaffichés.',
    'تبقى الملفات المرفوعة خاصة ولا تُعرض مجددًا.',
  );

  static String get ratingsTitle => _t('Évaluations', 'التقييمات');
  static String get ratingsAverage => _t('Note moyenne', 'متوسط التقييم');
  static String get ratingsCount => _t('Nombre d’évaluations', 'عدد التقييمات');
  static String get ratingsNone =>
      _t('Pas encore d’évaluation.', 'لا توجد تقييمات بعد.');

  static String get settingsTitle => _t('Réglages', 'الإعدادات');
  static String get settingsNotificationPrefs =>
      _t('Préférences de notification', 'تفضيلات الإشعارات');
  static String get settingsNotificationPrefsHint =>
      _t('Pas encore disponible', 'غير متاح بعد');

  // Onboarding
  static String get onboardingTitle =>
      _t('Inscription livreur', 'تسجيل السائق');
  static String get onboardingNext => _t('Continuer', 'متابعة');
  static String get onboardingStepProfile => _t('Informations', 'المعلومات');
  static String get onboardingStepIdentity => _t('Identité', 'الهوية');
  static String get onboardingStepLicense => _t('Permis', 'الرخصة');
  static String get onboardingStepVehicle => _t('Véhicule', 'المركبة');
  static String get onboardingStepReview => _t('Vérification', 'المراجعة');
  static String get fullNameLabel => _t('Nom complet', 'الاسم الكامل');
  static String get fullNameInvalid =>
      _t('Saisissez votre nom complet.', 'أدخل اسمك الكامل.');
  static String get identityTitle => _t('Pièce d’identité', 'وثيقة الهوية');
  static String get licenseTitle => _t('Permis de conduire', 'رخصة القيادة');
  static String get licenseExpiryLabel =>
      _t('Date d’expiration', 'تاريخ الانتهاء');
  static String get licenseExpiryHint => _t(
    'Le permis est obligatoire et doit être encore valide.',
    'الرخصة إلزامية ويجب أن تكون سارية.',
  );
  static String get licenseExpiryInvalid => _t(
    'Choisissez une date d’expiration valide (aujourd’hui ou plus tard).',
    'اختر تاريخ انتهاء صالحًا (اليوم أو بعده).',
  );
  static String get uploadPick => _t('Choisir un fichier', 'اختيار ملف');
  static String get uploadSend => _t('Envoyer', 'إرسال');
  static String get uploadFormats => _t(
    'PDF, JPEG ou PNG — 10 Mo maximum.',
    'PDF أو JPEG أو PNG — بحد أقصى 10 ميغابايت.',
  );
  static String get uploadPickerUnavailable => _t(
    'La sélection de fichier n’est pas disponible dans cette version de l’application.',
    'اختيار الملفات غير متاح في هذه النسخة من التطبيق.',
  );
  static String get uploadDone => _t('Document enregistré.', 'تم حفظ المستند.');
  static String get vehicleFormTitle => _t('Votre véhicule', 'مركبتك');
  static String get reviewTitle => _t('Vérifier et envoyer', 'مراجعة وإرسال');
  static String get reviewIntro => _t(
    'Le permis de conduire est obligatoire. Vérifiez que chaque étape est complète avant l’envoi.',
    'رخصة القيادة إلزامية. تأكد من اكتمال كل خطوة قبل الإرسال.',
  );
  static String get reviewSubmit =>
      _t('Envoyer pour vérification', 'إرسال للمراجعة');
  static String get stepDone => _t('Complété', 'مكتمل');
  static String get stepTodo => _t('À compléter', 'غير مكتمل');
  static String get appNameShort => 'SpeedyGo';
  static String get disconnect => _t('Déconnexion', 'تسجيل الخروج');
  static String get accountMenuTooltip => _t('Compte', 'الحساب');
  static String get reviewFullNameLabel => _t('Nom complet', 'الاسم الكامل');
  static String get reviewEdit => _t('Modifier', 'تعديل');

  static String get pendingMyDossier => _t('Mon dossier', 'ملفي');
  static String get pendingTitle => _t('Vérification en cours', 'التحقق جارٍ');
  static String get pendingTrackSubtitle =>
      _t('Suivez l’avancement de votre dossier.', 'تابع تقدم ملفك.');
  static String get pendingBody => _t(
    'Votre dossier a été envoyé et est actuellement en cours d’examen par notre équipe.',
    'تم إرسال ملفك وهو قيد المراجعة من قبل فريقنا.',
  );
  static String get pendingStatusBandTitle =>
      _t('En cours d’examen', 'قيد المراجعة');
  static String get pendingStatusBandBody =>
      _t('Notre équipe vérifie vos documents.', 'يراجع فريقنا مستنداتك.');
  static String get pendingTimelineSubmitted =>
      _t('Dossier envoyé', 'تم إرسال الملف');
  static String get pendingTimelineSubmittedMeta =>
      _t('Soumission enregistrée', 'تم تسجيل الإرسال');
  static String get pendingTimelineReview =>
      _t('Vérification par l’équipe', 'مراجعة الفريق');
  static String get pendingTimelineInProgress => _t('En cours', 'جارٍ');
  static String get pendingTimelineActivation =>
      _t('Activation du compte', 'تفعيل الحساب');
  static String get pendingTimelineAfterApproval =>
      _t('Après approbation', 'بعد الموافقة');
  static String get pendingDossierRefLabel =>
      _t('Référence du dossier', 'مرجع الملف');
  static String get pendingReviewNote => _t(
    'Actualisez le statut pour voir la décision dès qu’elle est disponible. Aucun délai exact n’est garanti dans l’application.',
    'حدّث الحالة لرؤية القرار عند توفره. لا يُضمن موعد محدد داخل التطبيق.',
  );
  static String get pendingRefreshCta =>
      _t('Actualiser le statut', 'تحديث الحالة');
  static String get pendingNeedHelp => _t('Besoin d’aide ?', 'تحتاج مساعدة؟');
  static String get pendingContactSupport =>
      _t('Contacter le support', 'التواصل مع الدعم');
  static String get pendingStatusPill =>
      _t('En attente d’approbation', 'بانتظار الموافقة');

  static String get approvedBadge => _t('Compte approuvé', 'حساب معتمد');
  static String approvedGreeting(String firstName) =>
      _t('Bonjour, $firstName', 'مرحبًا، $firstName');
  static String get approvedTitle =>
      _t('Prêt pour votre première livraison ?', 'جاهز لأول توصيل؟');
  static String get approvedBody => _t(
    'Votre compte est actif. Tout est prêt pour commencer.',
    'حسابك نشط. كل شيء جاهز للبدء.',
  );
  static String approvedWelcome(String name) => _t(
    'Bienvenue, $name. Votre compte est approuvé.',
    'مرحبًا، $name. تم اعتماد حسابك.',
  );
  static String get approvedCta =>
      _t('Accéder à l’espace livreur', 'الدخول إلى مساحة السائق');
  static String get approvedCheckGps => _t('GPS', 'GPS');
  static String get approvedCheckInternet => _t('Connexion', 'الاتصال');
  static String get approvedCheckUnknown => _t('À vérifier', 'يُتحقق');
  static String get approvedGpsOn => _t('Activé', 'مفعّل');
  static String get approvedGpsOff => _t('Désactivé', 'معطّل');
  static String get approvedGpsDenied => _t('Non autorisé', 'غير مسموح');
  static String get approvedConnUnknown => _t('Non mesurée', 'غير مقيسة');
  static String get approvedYourVehicle => _t('Votre véhicule', 'مركبتك');
  static String get approvedVehicleReady =>
      _t('Véhicule prêt pour les livraisons', 'المركبة جاهزة للتوصيل');
  static String get approvedVehicleNotReady =>
      _t('Véhicule non confirmé', 'المركبة غير مؤكدة');
  static String get approvedMyInfo =>
      _t('Mes informations approuvées', 'معلوماتي المعتمدة');
  static String get approvedInfoTitle =>
      _t('Informations approuvées', 'المعلومات المعتمدة');
  static String get approvedInfoReadOnlyNote => _t(
    'Lecture seule. Les modifications ne sont possibles qu’en cas de demande de correction.',
    'للقراءة فقط. التعديل ممكن فقط عند طلب تصحيح.',
  );

  static String get correctionsDossierTitle => _t('Mon dossier', 'ملفي');
  static String get correctionsTitle =>
      _t('Corrections requises', 'تصحيحات مطلوبة');
  static String get correctionsHeadline =>
      _t('Action requise sur votre dossier', 'إجراء مطلوب على ملفك');
  static String get correctionsHeadlinePhoto =>
      _t('Une pièce à reprendre', 'مستند يحتاج إعادة التقاط');
  static String get correctionsSubtitleHonest => _t(
    'Mettez à jour les éléments concernés, puis renvoyez votre dossier.',
    'حدّث العناصر المعنية ثم أعد إرسال ملفك.',
  );
  static String get correctionsBody => _t(
    'Votre dossier n’a pas été accepté. Mettez à jour les informations puis renvoyez-le.',
    'لم يُقبل ملفك. حدّث المعلومات ثم أعد الإرسال.',
  );
  static String get correctionsReasonLabel => _t('Motif', 'السبب');
  static String get correctionsReasonGeneral => _t(
    'Le dossier nécessite une correction. Le détail par champ n’est pas fourni par le serveur.',
    'يحتاج الملف إلى تصحيح. التفاصيل حسب الحقل غير متوفرة من الخادم.',
  );
  static String get correctionsGuidance => _t(
    'Reprenez une photo nette, bien éclairée, avec tous les textes visibles.',
    'أعد التقاط صورة واضحة وجيدة الإضاءة مع ظهور كل النصوص.',
  );
  static String get correctionsTipSharp => _t('Nette', 'واضحة');
  static String get correctionsTipSharpHint => _t('Sans flou', 'بدون ضباب');
  static String get correctionsTipLight => _t('Bien éclairée', 'إضاءة جيدة');
  static String get correctionsTipLightHint => _t('Sans ombre', 'بدون ظل');
  static String get correctionsTipFull => _t('Document entier', 'المستند كامل');
  static String get correctionsTipFullHint =>
      _t('Tous les bords visibles', 'كل الحواف ظاهرة');
  static String correctionsCountBadge(int count) =>
      _t('$count à corriger', '$count للتصحيح');
  static String correctionsSummary(int transmitted, int todo) => _t(
    '$transmitted élément(s) transmis · $todo correction(s)',
    '$transmitted عنصر(ات) مُرسلة · $todo تصحيح(ات)',
  );
  static String get correctionsCta =>
      _t('Renvoyer mon dossier', 'إعادة إرسال ملفي');
  static String get correctionsContinueLater =>
      _t('Continuer plus tard', 'المتابعة لاحقًا');
  static String get correctionsContinueLaterHint => _t(
    'Brouillon conservé pour ce compte. Vous pouvez reprendre depuis Corrections.',
    'المسودة محفوظة لهذا الحساب. يمكنك الاستئناف من التصحيحات.',
  );
  static String get correctionsReplacePhoto =>
      _t('Remplacer la photo', 'استبدال الصورة');
  static String get correctionsNeedsUpdate => _t('À corriger', 'يحتاج تصحيحًا');
  static String get correctionsTransmitted =>
      _t('Document transmis', 'مستند مُرسل');
  static String get correctionsMissingDoc =>
      _t('Document manquant', 'مستند ناقص');
  static String get correctionsValidatedSection =>
      _t('Éléments déjà transmis', 'عناصر مُرسلة مسبقًا');
  static String correctionsSeeTransmitted(int count) =>
      _t('Voir les $count éléments transmis', 'عرض $count عناصر مُرسلة');
  static String get correctionsPreviewUnavailable => _t(
    'Aperçu indisponible. Remplacez le document pour continuer.',
    'المعاينة غير متاحة. استبدل المستند للمتابعة.',
  );
  static String get correctionsPhotoSide =>
      _t('Photo du document', 'صورة المستند');
  static String get onboardingLocked => _t(
    'Votre dossier est verrouillé pendant la revue.',
    'ملفك مقفل أثناء المراجعة.',
  );

  // Support
  static String get supportTitle => _t('Support', 'الدعم');
  static String get supportEmpty =>
      _t('Aucune demande de support.', 'لا توجد طلبات دعم.');
  static String get supportNew => _t('Nouvelle demande', 'طلب جديد');
  static String get supportBodyLabel => _t('Décrivez votre demande', 'صف طلبك');
  static String get supportSend => _t('Envoyer', 'إرسال');
  static String get supportSent => _t('Demande envoyée.', 'تم إرسال الطلب.');
  static String get supportReplyHint => _t('Votre message', 'رسالتك');
  static String get supportDetailTitle => _t('Demande de support', 'طلب الدعم');
  static String get supportClosedNote => _t(
    'Cette demande est clôturée : vous ne pouvez plus répondre.',
    'أُغلق هذا الطلب: لا يمكنك الرد.',
  );
  static String get supportYou => _t('Vous', 'أنت');
  static String get supportTeam => _t('Support SpeedyGo', 'دعم SpeedyGo');
  static String supportStatusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return _t('Ouverte', 'مفتوح');
      case 'IN_PROGRESS':
        return _t('En cours', 'قيد المعالجة');
      case 'WAITING_USER':
        return _t('En attente de votre réponse', 'بانتظار ردك');
      case 'RESOLVED':
        return _t('Résolue', 'تم الحل');
      case 'CLOSED':
        return _t('Clôturée', 'مغلق');
      default:
        return status;
    }
  }

  // Notifications
  static String get notificationsTitle => _t('Notifications', 'الإشعارات');
  static String get notificationsEmpty =>
      _t('Aucune notification.', 'لا توجد إشعارات.');
  static String get notificationsMarkAll =>
      _t('Tout marquer comme lu', 'تعليم الكل كمقروء');
  static String get notificationsUnread => _t('Non lue', 'غير مقروءة');
  static String get notificationsLoadError =>
      _t('Impossible de charger les notifications.', 'تعذّر تحميل الإشعارات.');
  static String get notificationsMarkReadError => _t(
    'Impossible de mettre à jour l’état de lecture.',
    'تعذّر تحديث حالة القراءة.',
  );
  static String get notificationsDestinationUnavailable => _t(
    'Cette notification ne peut pas être ouverte ici.',
    'لا يمكن فتح هذا الإشعار هنا.',
  );
  static String get notificationsJustNow => _t('À l’instant', 'الآن');
  static String notificationsMinutesAgo(int count) =>
      _t('Il y a $count min', 'منذ $count د');
  static String notificationsHoursAgo(int count) =>
      _t('Il y a $count h', 'منذ $count س');
  static String notificationsDaysAgo(int count) =>
      _t('Il y a $count j', 'منذ $count ي');

  static String get notifTitleOrderAccepted =>
      _t('Commande acceptée', 'تم قبول الطلب');
  static String notifBodyOrderAccepted(String reference) => reference.isEmpty
      ? _t('La commande a été acceptée.', 'تم قبول الطلب.')
      : _t(
          'La commande $reference a été acceptée.',
          'تم قبول الطلب $reference.',
        );
  static String get notifTitleOrderRejected =>
      _t('Commande refusée', 'رُفض الطلب');
  static String notifBodyOrderRejected(String reference) => reference.isEmpty
      ? _t('La commande a été refusée.', 'رُفض الطلب.')
      : _t(
          'La commande $reference a été refusée.',
          'رُفض الطلب $reference.',
        );
  static String get notifTitleOrderCancelled =>
      _t('Commande annulée', 'أُلغي الطلب');
  static String notifBodyOrderCancelled(String reference) => reference.isEmpty
      ? _t('La commande a été annulée.', 'تم إلغاء الطلب.')
      : _t(
          'La commande $reference a été annulée.',
          'تم إلغاء الطلب $reference.',
        );
  static String get notifTitleOrderReady =>
      _t('Commande prête', 'الطلب جاهز');
  static String notifBodyOrderReady(String reference) => reference.isEmpty
      ? _t('La commande est prête.', 'الطلب جاهز.')
      : _t('La commande $reference est prête.', 'الطلب $reference جاهز.');
  static String get notifTitleDriverAssigned =>
      _t('Livreur assigné', 'تم تعيين مندوب');
  static String notifBodyDriverAssigned(String reference) => reference.isEmpty
      ? _t('Un livreur a été assigné.', 'تم تعيين مندوب.')
      : _t(
          'Un livreur a été assigné à la commande $reference.',
          'تم تعيين مندوب للطلب $reference.',
        );
  static String get notifTitleDeliveryCompleted =>
      _t('Commande livrée', 'تم التوصيل');
  static String notifBodyDeliveryCompleted(String reference) =>
      reference.isEmpty
      ? _t('La commande a été livrée.', 'تم توصيل الطلب.')
      : _t(
          'La commande $reference a été livrée.',
          'تم توصيل الطلب $reference.',
        );
  static String get notifTitlePaymentSucceeded =>
      _t('Paiement réussi', 'تم الدفع');
  static String notifBodyPaymentSucceeded(String reference) => reference.isEmpty
      ? _t('Le paiement a réussi.', 'تم تأكيد الدفع.')
      : _t(
          'Le paiement de la commande $reference a réussi.',
          'تم تأكيد الدفع للطلب $reference.',
        );
  static String get notifTitleRefundRefunded =>
      _t('Remboursement effectué', 'اكتمل الاسترداد');
  static String notifBodyRefundRefunded(String reference) => reference.isEmpty
      ? _t('Un remboursement a été effectué.', 'اكتمل استرداد للطلب.')
      : _t(
          'Un remboursement pour la commande $reference a été effectué.',
          'اكتمل استرداد للطلب $reference.',
        );
  static String get notifTitleMatchOffer =>
      _t('Nouvelle course proposée', 'عرض توصيل جديد');
  static String get notifBodyMatchOffer => _t(
    'Vous avez une nouvelle course. Ouvrez l’application pour accepter ou refuser avant expiration.',
    'لديك عرض توصيل جديد. افتح التطبيق للقبول أو الرفض قبل انتهاء المهلة.',
  );
  static String get notifTitleSettlementFinalized =>
      _t('Règlement finalisé', 'اكتمل التسوية');
  static String get notifBodySettlementFinalized => _t(
    'Un relevé de règlement est disponible. Ceci n’est pas une confirmation de virement.',
    'يتوفر كشف تسوية. هذا ليس تأكيد تحويل بنكي.',
  );
  static String get notifTitleDriverEarningCreated =>
      _t('Gain enregistré', 'سُجّل ربح');
  static String get notifBodyDriverEarningCreated => _t(
    'Un gain de livraison a été enregistré sur votre compte.',
    'سُجّل ربح توصيل في حسابك.',
  );
  static String get notifTitleMerchantOrderCreated =>
      _t('Nouvelle commande', 'طلب جديد');
  static String notifBodyMerchantOrderCreated(String reference) =>
      reference.isEmpty
      ? _t(
          'Une nouvelle commande nécessite votre attention.',
          'يتطلب طلب جديد انتباهك.',
        )
      : _t(
          'Une nouvelle commande $reference nécessite votre attention.',
          'يتطلب الطلب $reference انتباهك.',
        );

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

  static String locationApiErrorFor(String? code, {String? fallback}) {
    switch (code) {
      case 'DRIVER_LOCATION_REQUIRED':
      case 'DRIVER_DELIVERY_LOCATION_REQUIRED':
        return offerLocationRequired;
      case 'DRIVER_LOCATION_STALE':
      case 'DRIVER_DELIVERY_LOCATION_STALE':
        return offerLocationStale;
      case 'DRIVER_LOCATION_NOT_ALLOWED':
        return locationPermissionDenied;
      case 'DRIVER_LOCATION_STORE_UNAVAILABLE':
        return locationStoreUnavailable;
      case 'DRIVER_LOCATION_RATE_LIMITED':
        return locationRateLimited;
      case 'DRIVER_LOCATION_INVALID':
        return locationUnavailable;
      case 'NETWORK':
        return locationPublishFailed;
      default:
        return fallback ?? locationPublishFailed;
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
    // Display only: integer arithmetic, no float math on money.
    // Accepts legacy minor ("65000") or new DZD decimal ("650.00").
    final int value;
    if (minor.contains('.')) {
      final parts = minor.split('.');
      if (parts.length != 2 || parts[1].length > 2) {
        value = 0;
      } else {
        final whole = int.tryParse(parts[0]) ?? 0;
        final frac = int.tryParse(parts[1].padRight(2, '0')) ?? 0;
        value = whole * 100 + (whole < 0 ? -frac : frac);
      }
    } else {
      value = int.tryParse(minor) ?? 0;
    }
    final negative = value < 0;
    final abs = negative ? -value : value;
    final whole = abs ~/ 100;
    final cents = abs % 100;
    final text = cents == 0
        ? '$whole'
        : '$whole.${cents.toString().padLeft(2, '0')}';
    final signed = negative ? '-$text' : text;
    return isArabic ? '$signed د.ج' : '$signed DA';
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
      case 'AUTH_INVALID_OTP':
        return isArabic ? 'رمز غير صحيح.' : 'Code incorrect.';
      case 'AUTH_OTP_EXPIRED':
        return isArabic
            ? 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.'
            : 'Code expiré. Demandez-en un nouveau.';
      case 'AUTH_OTP_ATTEMPTS_EXCEEDED':
        return isArabic
            ? 'محاولات كثيرة. اطلب رمزًا جديدًا.'
            : 'Trop de tentatives. Demandez un nouveau code.';
      case 'AUTH_RATE_LIMITED':
        return isArabic
            ? 'طلبات كثيرة. أعد المحاولة لاحقًا.'
            : 'Trop de demandes. Réessayez plus tard.';
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
      case 'DRIVER_LOCATION_STORE_UNAVAILABLE':
        return locationStoreUnavailable;
      case 'DRIVER_LOCATION_RATE_LIMITED':
        return locationRateLimited;
      case 'DRIVER_LOCATION_INVALID':
        return locationUnavailable;
      case 'DRIVER_DELIVERY_COD_COMPLETION_NOT_READY':
      case 'DRIVER_COD_COLLECTION_NOT_READY':
        return _t(
          'Encaissez d’abord le montant COD exact avant de terminer.',
          'حصّل مبلغ الدفع عند الاستلام بالضبط قبل الإنهاء.',
        );
      case 'DRIVER_DELIVERY_PAYMENT_NOT_READY':
        return _t(
          'Le paiement n’est pas encore prêt pour terminer la livraison.',
          'الدفع غير جاهز لإنهاء التوصيل بعد.',
        );
      case 'DRIVER_DELIVERY_LOCATION_REQUIRED':
        return offerLocationRequired;
      case 'DRIVER_DELIVERY_LOCATION_STALE':
        return offerLocationStale;
      case 'DRIVER_DELIVERY_NOT_NEAR_PICKUP':
        return _t(
          'Vous êtes trop loin du commerçant (300 m max).',
          'أنت بعيد جدًا عن التاجر (300 م كحد أقصى).',
        );
      case 'DRIVER_DELIVERY_NOT_NEAR_DROPOFF':
        return _t(
          'Vous êtes trop loin de l’adresse du client (300 m max).',
          'أنت بعيد جدًا عن عنوان العميل (300 م كحد أقصى).',
        );
      case 'DRIVER_COD_COLLECTION_AMOUNT_MISMATCH':
        return _t(
          'Le montant ne correspond pas exactement au montant attendu.',
          'المبلغ لا يطابق المبلغ المتوقع بالضبط.',
        );
      case 'DRIVER_COD_COLLECTION_METHOD_NOT_COD':
        return _t(
          'Cette commande n’est pas payée à la livraison.',
          'هذا الطلب غير مدفوع عند الاستلام.',
        );
      case 'DRIVER_COD_COLLECTION_ALREADY_EXISTS':
        return _t(
          'L’encaissement est déjà enregistré.',
          'تم تسجيل التحصيل مسبقًا.',
        );
      case 'DRIVER_COD_COLLECTION_PAYMENT_NOT_ELIGIBLE':
      case 'DRIVER_COD_COLLECTION_ASSIGNMENT_NOT_ACTIVE':
        return invalidState;
      case 'DRIVER_COD_REMITTANCE_INVALID_AMOUNT':
        return _t('Montant invalide.', 'مبلغ غير صالح.');
      case 'DRIVER_COD_REMITTANCE_INSUFFICIENT_CUSTODY':
        return _t(
          'Le montant dépasse les espèces que vous devez remettre.',
          'المبلغ يتجاوز النقد المستحق عليك.',
        );
      case 'DRIVER_COD_REMITTANCE_OPEN_EXISTS':
        return _t(
          'Une déclaration est déjà en attente de confirmation.',
          'يوجد إقرار قيد انتظار التأكيد.',
        );
      case 'DRIVER_DOCUMENT_REQUIRED':
      case 'DRIVER_VEHICLE_REQUIRED':
      case 'DRIVER_LICENSE_REQUIRED':
        return _t(
          'Dossier incomplet : documents ou véhicule manquants.',
          'ملف غير مكتمل: مستندات أو مركبة ناقصة.',
        );
      case 'DRIVER_DOCUMENT_INVALID':
        return _t('Document invalide ou expiré.', 'مستند غير صالح أو منتهي.');
      case 'DRIVER_VEHICLE_CONFLICT':
        return _t(
          'Cette plaque est déjà utilisée.',
          'رقم اللوحة مستخدم بالفعل.',
        );
      case 'DRIVER_VERIFICATION_INVALID_STATE':
        return onboardingLocked;
      case 'SUPPORT_INVALID_STATE':
        return supportClosedNote;
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
