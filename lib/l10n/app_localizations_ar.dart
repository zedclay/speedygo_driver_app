// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'SpeedyGo سائق';

  @override
  String get networkError => 'تعذّر الاتصال. أعد المحاولة.';

  @override
  String get unexpectedError => 'حدث خطأ. أعد المحاولة.';

  @override
  String get sessionExpired => 'انتهت الجلسة. سجّل الدخول مجددًا.';

  @override
  String get phoneTitle => 'تسجيل دخول السائق';

  @override
  String get phoneHint => 'رقم الهاتف';

  @override
  String get phoneContinue => 'متابعة';

  @override
  String get phoneInvalid => 'أدخل رقمًا صالحًا.';

  @override
  String get otpTitle => 'رمز التحقق';

  @override
  String get otpHint => 'الرمز المستلم عبر الرسالة';

  @override
  String get otpVerify => 'تأكيد';

  @override
  String get otpResend => 'إعادة إرسال الرمز';

  @override
  String get deliveryTitle => 'الطلب الحالي';

  @override
  String get deliveryEmpty => 'لا توجد طلبية نشطة حاليًا.';

  @override
  String get deliveryRefresh => 'تحديث';

  @override
  String get deliveryLoading => 'جاري تحميل الطلبية…';

  @override
  String get confirmPickup => 'تأكيد الاستلام';

  @override
  String get confirmingPickup => 'جاري التأكيد…';

  @override
  String get pickupCodeLabel => 'رمز التاجر';

  @override
  String get pickupCodeHint => '٤ أرقام';

  @override
  String get pickupCodeHelp =>
      'اطلب الرمز المعروض لدى التاجر. اتركه فارغًا فقط إذا لم يُطلب رمز.';

  @override
  String get pickedUpSuccess => 'تم تأكيد الاستلام.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmBody => 'ستحتاج إلى إعادة تسجيل الدخول للمتابعة.';

  @override
  String get logoutConfirmAction => 'تسجيل الخروج';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get orderIdLabel => 'الطلب';

  @override
  String get assignmentLabel => 'التعيين';

  @override
  String get noDriverProfile => 'لا يوجد ملف سائق مرتبط بهذا الحساب.';

  @override
  String get languageSettingsTitle => 'اللغة';

  @override
  String get languageSettingsSubtitle =>
      'اختر لغة واجهة السائق. يُطبَّق التغيير فورًا دون تسجيل الخروج.';

  @override
  String get languageOptionFrench => 'Français';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageApply => 'تطبيق';

  @override
  String get languagePreviewNote =>
      'أرقام الهاتف ورموز الاستلام تبقى قابلة للقراءة من اليسار إلى اليمين.';

  @override
  String get codeInvalid => 'رمز غير صحيح. تحقّق منه لدى التاجر.';

  @override
  String get codeExpired =>
      'انتهت صلاحية الرمز. اطلب من التاجر إنشاء رمز جديد.';

  @override
  String get codeLocked => 'محاولات كثيرة. انتظر أو اطلب رمزًا جديدًا.';

  @override
  String get assignmentInactive => 'هذا التعيين لم يعد نشطًا.';

  @override
  String get invalidState => 'هذا الإجراء لم يعد متاحًا.';

  @override
  String get handoffInvalidState => 'التسليم لم يعد متاحًا. حدّث الطلبية.';

  @override
  String get assignmentConflict => 'تغيّر التعيين. حدّث الطلبية.';

  @override
  String get homeTitle => 'التوفر';

  @override
  String get homeLoading => 'جاري تحميل حالة التوفر…';

  @override
  String get availabilityOnline => 'متصل';

  @override
  String get availabilityOffline => 'غير متصل';

  @override
  String get availabilitySuspended => 'موقوف';

  @override
  String get availabilityOfflineAfterCurrent => 'غير متصل بعد التوصيل الحالي';

  @override
  String get goOnline => 'الاتصال';

  @override
  String get goOffline => 'قطع الاتصال';

  @override
  String get goingOnline => 'جاري الاتصال…';

  @override
  String get goingOffline => 'جاري قطع الاتصال…';

  @override
  String get waitingForOffer => 'في انتظار عرض توصيل…';

  @override
  String get waitingForOfferHint => 'ابقَ متصلًا مع موقع مفعّل لاستلام العروض.';

  @override
  String get offerTitle => 'عرض توصيل';

  @override
  String get offerCountdownLabel => 'ينتهي خلال';

  @override
  String get offerExpired => 'انتهت صلاحية العرض.';

  @override
  String get offerAccept => 'قبول';

  @override
  String get offerReject => 'رفض';

  @override
  String get offerAccepting => 'جاري القبول…';

  @override
  String get offerRejecting => 'جاري الرفض…';

  @override
  String get offerPickupLabel => 'الاستلام من';

  @override
  String get offerRemunerationLabel => 'أجر التوصيل';

  @override
  String get offerPickupDistanceLabel => 'المسافة إلى الاستلام';

  @override
  String get offerDeliveryDistanceLabel => 'المسافة إلى التسليم';

  @override
  String get offerOrderRefLabel => 'المرجع';

  @override
  String get openCurrentDelivery => 'فتح الطلب الحالي';

  @override
  String get activeDeliveryBanner =>
      'لديك طلب نشط. أكمل التسليم قبل عروض جديدة.';

  @override
  String get locationServicesDisabled => 'فعّل خدمات الموقع على الجهاز.';

  @override
  String get locationPermissionDenied =>
      'إذن الموقع مطلوب لاستلام العروض وقبولها.';

  @override
  String get locationPermissionDeniedForever =>
      'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات النظام.';

  @override
  String get locationUnavailable => 'تعذّر الحصول على الموقع.';

  @override
  String get locationTimeout => 'انتهت مهلة الحصول على الموقع.';

  @override
  String get locationPublishing => 'إرسال الموقع…';

  @override
  String get driverNotApproved => 'حسابك غير معتمد بعد. أكمل التحقق أولًا.';

  @override
  String get driverNotOperational =>
      'الملف غير جاهز للتشغيل (وثائق أو مركبة ناقصة).';

  @override
  String get driverAvailabilityInvalid =>
      'تعذّر تغيير حالة التوفر. حدّث ثم أعد المحاولة.';

  @override
  String get offerTakenOrStale => 'لم يعد هذا العرض متاحًا.';

  @override
  String get offerLocationRequired => 'يلزم موقع حديث لقبول العرض.';

  @override
  String get offerLocationStale => 'موقعك قديم. أعد المحاولة بعد تحديث الموقع.';

  @override
  String get notMatchingEligible => 'لست مؤهلًا للمطابقة حاليًا.';

  @override
  String get metersUnit => 'م';
}
