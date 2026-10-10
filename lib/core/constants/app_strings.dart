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
  static String get navPickupTitle =>
      _t('Navigation vers le commerçant', 'التنقل إلى التاجر');
  static String get navDropoffTitle =>
      _t('Navigation vers le client', 'التنقل إلى العميل');
  static String get navUnavailable => _t(
    'Navigation indisponible : aucune adresse ni application de cartes n’est fournie par le serveur pour cette course.',
    'التنقل غير متاح: لا يوفّر الخادم عنوانًا ولا تطبيق خرائط لهذا الطلب.',
  );
  static String get navCopyHint => _t(
    'Copiez l’adresse puis ouvrez-la dans l’application de cartes de votre choix.',
    'انسخ العنوان ثم افتحه في تطبيق الخرائط الذي تفضّله.',
  );
  static String get navCopy => _t('Copier', 'نسخ');
  static String get navCopied => _t('Copié.', 'تم النسخ.');
  static String get navDistance => _t('Distance', 'المسافة');

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
    'Montant encaissé (unités mineures)',
    'المبلغ المحصّل (بالوحدات الصغرى)',
  );
  static String get codAmountHelp => _t(
    'Entier en centimes. Le montant doit correspondre exactement à celui attendu par le serveur.',
    'عدد صحيح بالسنتيم. يجب أن يطابق المبلغ ما يتوقعه الخادم تمامًا.',
  );
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
      _t('Montant remis (centimes)', 'المبلغ المسلَّم (بالسنتيم)');
  static String get codRemitHelp => _t(
    'La déclaration ne réduit pas votre solde tant que SpeedyGo ne l’a pas confirmée.',
    'لا يخفض الإقرار رصيدك حتى تؤكده SpeedyGo.',
  );
  static String get codRemitSubmit => _t('Déclarer', 'إقرار');
  static String get codRemitSuccess =>
      _t('Remise déclarée.', 'تم إقرار التسليم.');

  // Profile
  static String get profileTitle => _t('Profil', 'الملف الشخصي');
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
      _t('Date d’expiration (AAAA-MM-JJ)', 'تاريخ الانتهاء (YYYY-MM-DD)');
  static String get licenseExpiryHint => _t(
    'Le permis est obligatoire et doit être encore valide.',
    'الرخصة إلزامية ويجب أن تكون سارية.',
  );
  static String get licenseExpiryInvalid =>
      _t('Format attendu : AAAA-MM-JJ.', 'الصيغة المطلوبة: YYYY-MM-DD.');
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
  static String get pendingTitle =>
      _t('Dossier en cours de revue', 'الملف قيد المراجعة');
  static String get pendingBody => _t(
    'Notre équipe examine votre dossier. Vous serez notifié dès qu’une décision sera prise.',
    'يراجع فريقنا ملفك. سيصلك إشعار عند اتخاذ القرار.',
  );
  static String get approvedTitle => _t('Dossier approuvé', 'تم اعتماد الملف');
  static String get approvedBody => _t(
    'Vous pouvez passer en ligne et recevoir des offres.',
    'يمكنك الاتصال واستلام العروض.',
  );
  static String get approvedCta => _t('Commencer', 'ابدأ');
  static String get correctionsTitle =>
      _t('Corrections requises', 'تصحيحات مطلوبة');
  static String get correctionsBody => _t(
    'Votre dossier n’a pas été accepté. Mettez à jour les informations puis renvoyez-le.',
    'لم يُقبل ملفك. حدّث المعلومات ثم أعد الإرسال.',
  );
  static String get correctionsCta => _t('Corriger mon dossier', 'تصحيح ملفي');
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
    // Display only: integer arithmetic, no float math on money.
    final value = int.tryParse(minor) ?? 0;
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
