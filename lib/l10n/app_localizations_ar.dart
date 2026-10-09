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
}
