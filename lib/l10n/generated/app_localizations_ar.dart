// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مخزون البضائع';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get forgotEmailHint => 'سنرسل رمزًا إلى هذا العنوان.';

  @override
  String get forgotCodeHint => 'أدخل الرمز من البريد الإلكتروني.';

  @override
  String get forgotPasswordHint => '8 أحرف على الأقل.';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get verifyCode => 'تحقق من الرمز';

  @override
  String get verificationCode => 'رمز من 6 أرقام';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get savePassword => 'حفظ كلمة المرور';

  @override
  String get passwordTooShort => '8 أحرف على الأقل.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get backToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get home => 'الرئيسية';

  @override
  String get tours => 'الجولات';

  @override
  String get stock => 'المخزون';

  @override
  String get reports => 'التقارير';

  @override
  String get more => 'المزيد';

  @override
  String get back => 'رجوع';

  @override
  String greetingMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String greetingDay(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String greetingEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get areas => 'الأقسام';

  @override
  String get onboardingStockTitle => 'المنتجات والأسعار';

  @override
  String get onboardingStockText =>
      'أنشئ المنتجات مع الوحدة وحجم الكرتونة والأسعار.';

  @override
  String get onboardingToursTitle => 'حساب الجولات';

  @override
  String get onboardingToursText => 'تسجيل الحمولة والمرتجع ومطابقة الصندوق.';

  @override
  String get onboardingDocumentsTitle => 'السندات والفواتير';

  @override
  String get onboardingDocumentsText =>
      'إيصالات التسليم والفواتير والمصروفات بصيغة PDF.';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingStart => 'إلى تسجيل الدخول';

  @override
  String onboardingPage(int current, int total) {
    return '$current من $total';
  }

  @override
  String get drivers => 'السائقون';

  @override
  String get newDriver => 'إضافة سائق';

  @override
  String get editDriver => 'تعديل السائق';

  @override
  String get driverName => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get vehicle => 'المركبة / رقم اللوحة';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get noDrivers => 'لا يوجد سائقون بعد.';

  @override
  String get noResults => 'لا توجد نتائج.';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'موافق';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get reactivate => 'تفعيل';

  @override
  String get search => 'بحث';

  @override
  String get requiredField => 'يرجى تعبئة الحقل.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get reload => 'إعادة التحميل';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get conflict => 'تم تغيير السجل في هذه الأثناء. يرجى إعادة التحميل.';

  @override
  String conflictBy(String name) {
    return 'تم تغييره في هذه الأثناء بواسطة $name. يرجى إعادة التحميل.';
  }

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get configurationMissing => 'إعدادات التطبيق مفقودة أو غير صالحة.';

  @override
  String get accessDenied => 'متاح لدور المدير فقط.';

  @override
  String get featureUnavailable => 'غير متاح بعد.';

  @override
  String get unknownError => 'حدث خطأ غير متوقع.';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get codeExpired => 'انتهت صلاحية الرمز. يرجى طلب رمز جديد.';

  @override
  String get codeInvalid => 'الرمز غير صالح.';

  @override
  String get authFailed => 'فشل تسجيل الدخول.';

  @override
  String get codeSent => 'تم إرسال الرمز بالبريد الإلكتروني.';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور.';

  @override
  String get cartons => 'كراتين';

  @override
  String get loosePieces => 'قطع منفردة';

  @override
  String get cashBalanced => 'الصندوق مطابق';

  @override
  String shortfall(String amount) {
    return 'نقد أقل $amount. يخفض الربح.';
  }

  @override
  String surplus(String amount) {
    return 'نقد أكثر $amount. يُحسب ضمن الربح.';
  }

  @override
  String get planTour => 'تخطيط جولة';

  @override
  String get loadTour => 'تحميل الجولة';

  @override
  String get tourDetails => 'الجولة';

  @override
  String get closeTour => 'إنهاء الجولة';

  @override
  String get stockIntake => 'إدخال بضاعة';

  @override
  String get newProduct => 'إضافة منتج';

  @override
  String get productDetails => 'المنتج';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get correctStock => 'تصحيح المخزون';

  @override
  String get importProducts => 'استيراد CSV';

  @override
  String get driverStats => 'إحصاءات السائقين';

  @override
  String get newExpense => 'تسجيل مصروف';

  @override
  String get expenseDetails => 'المصروف';

  @override
  String get newDeliveryNote => 'إنشاء إيصال تسليم';

  @override
  String get deliveryNoteDetails => 'إيصال التسليم';

  @override
  String get signDeliveryNote => 'التوقيع';

  @override
  String get newInvoice => 'إنشاء فاتورة';

  @override
  String get invoiceDetails => 'الفاتورة';

  @override
  String get pdfPreview => 'معاينة PDF';

  @override
  String get stockValue => 'قيمة المخزون';

  @override
  String productCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج',
      many: '$count منتجًا',
      few: '$count منتجات',
      two: 'منتجان',
      one: 'منتج واحد',
      zero: 'لا منتجات',
    );
    return '$_temp0';
  }

  @override
  String belowMinBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج دون الحد الأدنى',
      many: '$count منتجًا دون الحد الأدنى',
      few: '$count منتجات دون الحد الأدنى',
      two: 'منتجان دون الحد الأدنى',
      one: 'منتج واحد دون الحد الأدنى',
    );
    return '$_temp0';
  }

  @override
  String get searchProducts => 'اسم المنتج أو رقم الصنف';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterLow => 'منخفض';

  @override
  String get filterInactive => 'غير نشط';

  @override
  String get filterCategory => 'الفئة';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get noProducts => 'لا توجد منتجات بعد.';

  @override
  String get reorderHint =>
      'اضغط مطولًا على المنتج واسحبه، أو اضغط على الرقم واكتب الموضع. يُحفظ الترتيب فورًا ويُطبَّق أيضًا في الجولات وإيصالات التسليم والفواتير.';

  @override
  String get reorderStart => 'تغيير الترتيب';

  @override
  String get reorderSaved => 'تم حفظ الترتيب';

  @override
  String get reorderPositionTitle => 'الموضع الجديد';

  @override
  String reorderPositionHint(int max) {
    return 'رقم من 1 إلى $max';
  }

  @override
  String get low => 'منخفض';

  @override
  String get menu => 'القائمة';

  @override
  String get stockLabel => 'المخزون';

  @override
  String get minStockLabel => 'الحد الأدنى';

  @override
  String get pricesSection => 'الأسعار';

  @override
  String get buyPriceNet => 'الشراء صافي';

  @override
  String get sellPriceNet => 'البيع صافي';

  @override
  String get margin => 'الهامش';

  @override
  String get vatRate => 'ضريبة القيمة المضافة';

  @override
  String get movementsSection => 'الحركات';

  @override
  String get noMovements => 'لا توجد حركات بعد.';

  @override
  String get edit => 'تعديل';

  @override
  String get skuLabel => 'رقم الصنف';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get movementIntake => 'إدخال بضاعة';

  @override
  String get movementTourOut => 'جولة';

  @override
  String get movementTourReturn => 'مرتجع';

  @override
  String get movementTourUndo => 'إلغاء بدء الجولة';

  @override
  String get movementInvoice => 'فاتورة';

  @override
  String get movementInvoiceCancel => 'إلغاء فاتورة';

  @override
  String get movementCorrection => 'تصحيح';

  @override
  String get productName => 'الاسم';

  @override
  String get unitLabel => 'الوحدة';

  @override
  String get unitCarton => 'كرتونة';

  @override
  String get unitPiece => 'قطعة';

  @override
  String get unitJar => 'برطمان';

  @override
  String get unitKg => 'كيلوغرام';

  @override
  String get unitsPerCarton => 'عدد القطع في الكرتونة';

  @override
  String get buyPriceField => 'سعر الشراء صافي';

  @override
  String get sellPriceField => 'سعر البيع صافي';

  @override
  String get priceHint => 'السعر لكل وحدة، وللكيلوغرام عند الوزن.';

  @override
  String get initialStock => 'المخزون الابتدائي';

  @override
  String get invalidAmount => 'مبلغ غير صالح.';

  @override
  String get saved => 'تم الحفظ.';

  @override
  String get chooseProduct => 'اختر منتجًا';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get noteLabel => 'ملاحظة';

  @override
  String newStockPreview(String text) {
    return 'المخزون الجديد: $text';
  }

  @override
  String get bookIntake => 'تسجيل إدخال البضاعة';

  @override
  String get intakeBooked => 'تم تسجيل إدخال البضاعة.';

  @override
  String get quantityMustBePositive => 'يجب أن تكون الكمية أكبر من 0.';

  @override
  String get currentStock => 'الحالي';

  @override
  String get newStockLabel => 'المخزون الجديد';

  @override
  String get differenceLabel => 'الفرق';

  @override
  String get reasonLabel => 'السبب (اختياري)';

  @override
  String get reasonBreakage => 'كسر';

  @override
  String get reasonInventory => 'جرد';

  @override
  String get reasonOther => 'أخرى';

  @override
  String get reasonRequired => 'يرجى إدخال سبب.';

  @override
  String get bookCorrection => 'تسجيل التصحيح';

  @override
  String get correctionBooked => 'تم تسجيل التصحيح.';

  @override
  String cartonsExpression(String text) {
    return '= $text';
  }

  @override
  String get unitCartonOne => 'كرتونة';

  @override
  String get unitJarOne => 'برطمان';

  @override
  String get unitJarMany => 'برطمانات';

  @override
  String get unitKgShort => 'كغ';

  @override
  String get toursSearch => 'السائق أو رقم الجولة';

  @override
  String get notAvailable => '–';

  @override
  String get tourStatusDraft => 'مخططة';

  @override
  String get tourStatusActive => 'في الطريق';

  @override
  String get tourStatusClosed => 'مكتملة';

  @override
  String get noTours => 'لا توجد جولات بعد.';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get stepDetails => 'التفاصيل';

  @override
  String get stepLoad => 'التحميل';

  @override
  String get driverLabel => 'السائق';

  @override
  String get chooseDriver => 'اختر سائقًا';

  @override
  String get plannedAtLabel => 'التاريخ والوقت';

  @override
  String get tourNameOptional => 'اسم الجولة (اختياري)';

  @override
  String get next => 'التالي';

  @override
  String availableStock(String text) {
    return 'المخزون: $text';
  }

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get pickPerKilogram => 'بالكيلوغرام';

  @override
  String get remove => 'إزالة';

  @override
  String get loadValueBuy => 'قيمة البضاعة بسعر الشراء';

  @override
  String get loadValueSell => 'قيمة البضاعة بسعر البيع';

  @override
  String get expectedProfit => 'الربح المتوقع';

  @override
  String stockNotEnough(String name) {
    return 'المخزون غير كافٍ لـ $name.';
  }

  @override
  String get startTour => 'بدء الجولة';

  @override
  String get saveDraft => 'حفظ كمسودة';

  @override
  String get confirmStartTour => 'سيتم خصم البضاعة من المخزون.';

  @override
  String get noItemsYet => 'لا توجد منتجات بعد.';

  @override
  String get tourLoad => 'الحمولة';

  @override
  String get tourValues => 'القيم';

  @override
  String get expectedRevenue => 'الإيراد المتوقع';

  @override
  String get tourStarted => 'بدأت الجولة.';

  @override
  String get draftSaved => 'تم حفظ المسودة.';

  @override
  String get draftRestored =>
      'عادت مسودتك التي بدأتها. يمكنك المتابعة من حيث توقفت.';

  @override
  String get undoStart => 'التراجع عن البدء';

  @override
  String get confirmUndoStart => 'ستعود البضاعة إلى المخزون.';

  @override
  String get reopenTour => 'إعادة الفتح';

  @override
  String get delete => 'حذف';

  @override
  String get confirmDeleteDraft => 'حذف هذه المسودة؟';

  @override
  String get revenue => 'الإيراد';

  @override
  String get expectedCash => 'النقد المطلوب';

  @override
  String get cashReceived => 'النقد المسلَّم';

  @override
  String get costOfGoods => 'تكلفة البضاعة';

  @override
  String get profit => 'الربح';

  @override
  String get startedAtLabel => 'البدء';

  @override
  String get closedAtLabel => 'الانتهاء';

  @override
  String get tourNumberLabel => 'رقم الجولة';

  @override
  String get noDriversAvailable => 'لا يوجد سائقون نشطون.';

  @override
  String get soldLabel => 'المباع';

  @override
  String get returnedLabel => 'المرتجع';

  @override
  String get loadedLabel => 'المحمَّل';

  @override
  String get closeInfo => 'المباع = المحمَّل − المرتجع.';

  @override
  String get returnedQty => 'المرتجع';

  @override
  String loadedValue(String text) {
    return 'المحمَّل: $text';
  }

  @override
  String soldValue(String text, String amount) {
    return 'المباع: $text · $amount';
  }

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get expenseType => 'النوع';

  @override
  String get expenseDiesel => 'ديزل';

  @override
  String get expenseMeal => 'طعام';

  @override
  String get expenseParking => 'موقف سيارات';

  @override
  String get expenseOther => 'أخرى';

  @override
  String get amountGross => 'المبلغ شامل الضريبة';

  @override
  String get cashFromDriver => 'النقد من السائق';

  @override
  String returnTooHigh(String name) {
    return 'المرتجع من $name أكبر من المحمَّل.';
  }

  @override
  String get confirmCloseTour => 'ستُغلق الجولة ولا يمكن تعديلها.';

  @override
  String get confirmClose => 'تأكيد الإغلاق';

  @override
  String get tourClosed => 'تم إغلاق الجولة.';

  @override
  String get differenceReasonRequired => 'عند وجود فرق يلزم ذكر السبب.';

  @override
  String get cashRequired => 'يرجى إدخال النقد المسلَّم.';

  @override
  String get deliveryNotesSearch => 'المستلم أو الرقم';

  @override
  String get filterSigned => 'موقَّع';

  @override
  String get filterOpenNotes => 'مفتوح';

  @override
  String get statusSigned => 'موقَّع';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get noDeliveryNotes => 'لا توجد إيصالات تسليم بعد.';

  @override
  String get recipientName => 'المستلم';

  @override
  String get recipientAddress => 'العنوان';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get tourOptional => 'الجولة (اختياري)';

  @override
  String get chooseTour => 'اختر جولة';

  @override
  String get noTour => 'بدون جولة';

  @override
  String get tourItemsTaken => 'تم أخذ منتجات الجولة.';

  @override
  String get showPreview => 'معاينة';

  @override
  String get showPdf => 'عرض PDF';

  @override
  String get signAction => 'التوقيع';

  @override
  String get signConfirmText => 'تأكيد استلام البضاعة.';

  @override
  String get signerName => 'اسم الموقِّع';

  @override
  String get clearSignature => 'مسح';

  @override
  String get takeSignature => 'اعتماد التوقيع';

  @override
  String get signHere => 'وقِّع هنا';

  @override
  String get signatureMissing => 'يرجى التوقيع.';

  @override
  String get signerRequired => 'يرجى إدخال الاسم.';

  @override
  String get signedDone => 'تم التوقيع.';

  @override
  String get createInvoiceFromNote => 'إنشاء فاتورة منه';

  @override
  String get share => 'مشاركة';

  @override
  String get print => 'طباعة';

  @override
  String signedBy(String name, String date) {
    return '$name، $date';
  }

  @override
  String get confirmDeleteNote => 'حذف إيصال التسليم هذا؟';

  @override
  String get itemsRequired => 'يرجى إدخال منتج واحد على الأقل مع الكمية.';

  @override
  String get pdfNotStored => 'تم التوقيع، لكن لم يُحفظ ملف PDF بعد.';

  @override
  String expensesSummary(int count, String net) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سند',
      many: '$count سندًا',
      few: '$count سندات',
      two: 'سندان',
      one: 'سند واحد',
    );
    return '$_temp0 · صافي $net';
  }

  @override
  String get filterTourCosts => 'تكاليف الجولات';

  @override
  String get filterOtherExpenses => 'أخرى';

  @override
  String get withReceipt => 'سند';

  @override
  String get withoutReceipt => 'بدون سند';

  @override
  String get exportMonthPdf => 'تصدير الشهر بصيغة PDF';

  @override
  String get noExpenses => 'لا توجد مصروفات في هذا الشهر.';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get takePhoto => 'تصوير السند';

  @override
  String get pickFromGallery => 'من المعرض';

  @override
  String get scanReceipt => 'مسح السند';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get expenseTitle => 'البيان';

  @override
  String netAmount(String amount) {
    return 'الصافي: $amount';
  }

  @override
  String get categoryVehicle => 'مركبات ووقود';

  @override
  String get categoryRent => 'إيجار';

  @override
  String get categoryMaintenance => 'صيانة';

  @override
  String get categoryMeals => 'طعام';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get shareAsPdf => 'مشاركة بصيغة PDF';

  @override
  String get photoFailed => 'تعذّرت معالجة الصورة.';

  @override
  String get confirmDeleteExpense => 'حذف هذا المصروف؟';

  @override
  String get tourCostsLocked => 'مصروف جولة.';

  @override
  String get viewImage => 'عرض السند';

  @override
  String get netLabel => 'الصافي';

  @override
  String get invoicesSearch => 'المستلم أو رقم الفاتورة';

  @override
  String get filterPaid => 'مدفوعة';

  @override
  String get filterOverdue => 'متأخرة';

  @override
  String get filterDrafts => 'مسودات';

  @override
  String get statusOpenInvoice => 'مفتوحة';

  @override
  String get statusPaid => 'مدفوعة';

  @override
  String get statusOverdue => 'متأخرة';

  @override
  String get statusCancelled => 'ملغاة';

  @override
  String openSummary(int count) {
    return '$count متأخرة';
  }

  @override
  String get noInvoices => 'لا توجد فواتير بعد.';

  @override
  String get recipientVatId => 'الرقم الضريبي للمستلم (اختياري)';

  @override
  String get invoiceDateLabel => 'تاريخ الفاتورة';

  @override
  String get serviceDateLabel => 'تاريخ الخدمة';

  @override
  String get dueDateLabel => 'تاريخ الاستحقاق';

  @override
  String paymentTermInfo(int days, String date) {
    return 'مهلة الدفع $days يومًا، الاستحقاق $date';
  }

  @override
  String get positionsSection => 'البنود';

  @override
  String get addFreeItem => 'بند حر';

  @override
  String get itemName => 'البيان';

  @override
  String get itemUnit => 'الوحدة';

  @override
  String get unitPriceNetField => 'السعر صافي';

  @override
  String lineTotal(String amount) {
    return 'المجموع: $amount';
  }

  @override
  String get vat7Row => 'ضريبة 7 %';

  @override
  String get vat19Row => 'ضريبة 19 %';

  @override
  String get grossTotal => 'الإجمالي شامل الضريبة';

  @override
  String get invoiceNote => 'نص الملاحظة';

  @override
  String get finalizeAction => 'اعتماد نهائي';

  @override
  String get confirmFinalize => 'لا يمكن التعديل بعد الاعتماد.';

  @override
  String invoiceFinalized(String number) {
    return 'تم اعتماد الفاتورة $number.';
  }

  @override
  String get markPaid => 'تحديد كمدفوعة';

  @override
  String get markUnpaid => 'إعادتها إلى مفتوحة';

  @override
  String get cancelInvoiceAction => 'إلغاء';

  @override
  String get confirmCancelInvoice =>
      'ستُنشأ فاتورة إلغاء وتعود البضاعة إلى المخزون.';

  @override
  String get invoiceCancelled => 'تم الإلغاء.';

  @override
  String get paidAtLabel => 'تاريخ الدفع';

  @override
  String get deliveryNoteRefLabel => 'إيصال التسليم';

  @override
  String get cancellationOfLabel => 'إلغاء للفاتورة';

  @override
  String get invoiceDraftTitle => 'مسودة فاتورة';

  @override
  String get smallBusinessHint => 'منشأة صغيرة: بدون ضريبة قيمة مضافة.';

  @override
  String get freeItemName => 'اسم البند';

  @override
  String get rangeDay => 'يوم';

  @override
  String get rangeWeek => 'أسبوع';

  @override
  String get rangeMonth => 'شهر';

  @override
  String get rangeYear => 'سنة';

  @override
  String get rangeCustom => 'مخصص';

  @override
  String get weekShort => 'أسبوع';

  @override
  String get kpiSection => 'المؤشرات';

  @override
  String changeToPrevious(String percent) {
    return '$percent % مقارنة بالفترة السابقة';
  }

  @override
  String get chartRevenueVsExpenses => 'الإيرادات والمصروفات';

  @override
  String get topProducts => 'أفضل المنتجات';

  @override
  String get expensesByCategory => 'المصروفات حسب الفئة';

  @override
  String get reportPdf => 'التقرير بصيغة PDF';

  @override
  String get noReportData => 'لا توجد بيانات في هذه الفترة.';

  @override
  String get averagePerTour => 'المتوسط لكل جولة';

  @override
  String get returnRate => 'نسبة المرتجع';

  @override
  String get differences => 'فروقات الصندوق';

  @override
  String get expenses => 'المصروفات';

  @override
  String get deliveryNotes => 'إيصالات التسليم';

  @override
  String get invoices => 'الفواتير';

  @override
  String get users => 'المستخدمون';

  @override
  String get company => 'بيانات الشركة';

  @override
  String get account => 'الحساب';

  @override
  String get help => 'مساعدة';

  @override
  String get products => 'المنتجات';

  @override
  String get updateRequired => 'يرجى التحديث';

  @override
  String get noConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get discardChangesTitle => 'تجاهل التغييرات؟';

  @override
  String get discardChangesMessage => 'ستفقد المدخلات غير المحفوظة.';

  @override
  String get discard => 'تجاهل';

  @override
  String get checkAmount => 'يرجى التحقق من المبلغ. الفرق أكبر من 50 يورو.';

  @override
  String get onRoadToday => 'في الطريق اليوم';

  @override
  String get noTourOnRoad => 'لا توجد جولة في الطريق';

  @override
  String get monthOverview => 'نظرة عامة على الشهر';

  @override
  String get tileToursSub => 'التخطيط والتسوية';

  @override
  String get tileStockSub => 'إدخال البضائع والتصحيح';

  @override
  String get tileExpensesSub => 'الإيصالات والمصروفات';

  @override
  String get tileDeliverySub => 'الإنشاء والتوقيع';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get companyAddress => 'العنوان';

  @override
  String get taxNumber => 'الرقم الضريبي';

  @override
  String get vatId => 'رقم ضريبة القيمة المضافة';

  @override
  String get iban => 'IBAN';

  @override
  String get bic => 'BIC';

  @override
  String get bankName => 'البنك';

  @override
  String get managingDirector => 'المدير';

  @override
  String get paymentTermDays => 'مهلة الدفع بالأيام';

  @override
  String get invoiceFooter => 'النص أسفل الفاتورة';

  @override
  String get cashIncludesVat => 'السائق يحصّل الأسعار شاملة الضريبة';

  @override
  String get smallBusiness => 'منشأة صغيرة (§ 19 UStG)';

  @override
  String get smallBusinessNote => 'ملاحظة على الفاتورة';

  @override
  String get companySaved => 'تم حفظ بيانات الشركة';

  @override
  String get companyOnlyChef => 'المدير فقط يمكنه تعديل بيانات الشركة.';

  @override
  String get accountName => 'الاسم';

  @override
  String get role => 'الدور';

  @override
  String get roleChef => 'المدير';

  @override
  String get roleOffice => 'الإدارة';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountMessage =>
      'سيتم حذف حسابك والوصول نهائيًا. لا يمكن التراجع عن ذلك.';

  @override
  String get nameSaved => 'تم حفظ الاسم';

  @override
  String get usersHint =>
      'مستخدمو شركتك. يرون البيانات نفسها ويمكنهم فعل كل شيء مثلك.';

  @override
  String get makeChef => 'تعيين كمدير';

  @override
  String get makeOffice => 'تعيين كإدارة';

  @override
  String get helpTourTitle => 'تخطيط الجولة وتسويتها';

  @override
  String get helpTourText =>
      'اختر السائق وأدخل المنتجات والكميات ثم ابدأ الجولة. بعد العودة أدخل المرتجعات والنقد ثم أغلق الجولة. المباع = المحمّل − المرتجع. النقد المتوقع = الإيراد − المصروفات.';

  @override
  String get helpStockTitle => 'المنتجات';

  @override
  String get helpStockText =>
      'أنشئ المنتجات مع الوحدة وحجم الكرتونة والأسعار. لا يوجد مخزون: عند التحميل تكتب فقط الكمية التي تذهب مع السائق.';

  @override
  String get helpDocsTitle => 'إشعار التسليم والفاتورة';

  @override
  String get helpDocsText =>
      'اطلب توقيع إشعارات التسليم وشاركها كملف PDF. يمكنك تعديل الفاتورة حتى تثبيتها، وتختار ضريبة القيمة المضافة لكل بند. يمكن حذف كل شيء، حتى الجولات والفواتير. عند حذف فاتورة مثبّتة يسألك التطبيق أولاً لأنها يجب أن تُحفظ.';

  @override
  String get helpExpensesTitle => 'الإيصالات';

  @override
  String get helpExpensesText =>
      'صوّر الإيصال وأدخل المبلغ والفئة ثم احفظ. في الشهر ترى كل الإيصالات ويمكنك إرسالها كملف PDF إلى المحاسب.';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get dueToday => 'مستحق اليوم';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستحق خلال $count يومًا',
      few: 'مستحق خلال $count أيام',
      two: 'مستحق خلال يومين',
      one: 'مستحق خلال يوم',
    );
    return '$_temp0';
  }

  @override
  String overdueSinceDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر منذ $count يومًا',
      few: 'متأخر منذ $count أيام',
      two: 'متأخر منذ يومين',
      one: 'متأخر منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get language => 'اللغة';

  @override
  String get languageDevice => 'الجهاز';

  @override
  String get bundles => 'الكراتين المختلطة';

  @override
  String get newBundle => 'كرتونة مختلطة جديدة';

  @override
  String get editBundle => 'تعديل الكرتونة المختلطة';

  @override
  String get bundleName => 'الاسم';

  @override
  String get bundleContents => 'المحتوى';

  @override
  String get noBundles => 'لا توجد كراتين مختلطة بعد.';

  @override
  String get bundleHint =>
      'عند التحميل تُحوَّل الكرتونة المختلطة إلى منتجاتها وينقص مخزون هذه المنتجات.';

  @override
  String get bundleNeedsProduct => 'أضف منتجًا واحدًا على الأقل.';

  @override
  String get confirmDeleteBundle =>
      'حذف هذه الكرتونة المختلطة؟ لن يتغير المخزون بسبب ذلك.';

  @override
  String get addBundle => 'إضافة كرتونة مختلطة';

  @override
  String get bundleCountTitle => 'كم كرتونة مختلطة؟';

  @override
  String get bundleCount => 'العدد';

  @override
  String get bundleProductMissing =>
      'أحد منتجات الكرتونة المختلطة لم يعد نشطًا ولم تتم إضافته.';

  @override
  String get navReports => 'التقارير';

  @override
  String get gifts => 'المنتجات المهداة';

  @override
  String get addGift => 'إضافة هدية';

  @override
  String giftMax(String max) {
    return 'الحد الأقصى $max. الهدايا لا تُحتسب في الإيراد.';
  }

  @override
  String get newUser => 'مستخدم جديد';

  @override
  String get newUserHint =>
      'يرى المستخدم البيانات نفسها ويمكنه فعل كل شيء. أعطه كلمة المرور، ويمكنه تغييرها لاحقًا من الحساب.';

  @override
  String get createUser => 'إنشاء المستخدم';

  @override
  String get userCreated => 'تم إنشاء المستخدم';

  @override
  String get select => 'تحديد';

  @override
  String get done => 'تم';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء التحديد';

  @override
  String selectionCount(int count) {
    return '$count محدد';
  }

  @override
  String get exportSelectionPdf => 'تصدير المحدد كملف PDF';

  @override
  String get tileProductsSub => 'المنتجات والأسعار';

  @override
  String get confirmDeleteTour =>
      'ستُحذف هذه الجولة نهائيًا مع كل بنودها ومصروفاتها. لا يمكن التراجع عن ذلك.';

  @override
  String get confirmDeleteSignedNote =>
      'سيُحذف إشعار التسليم الموقّع نهائيًا. لا يمكن التراجع عن ذلك.';

  @override
  String get confirmDeleteInvoice =>
      'تنبيه: يجب الاحتفاظ بالفاتورة المثبّتة 8 سنوات في ألمانيا. إذا حذفتها يختفي رقمها ولا يمكن التراجع. هل تريد الحذف فعلًا؟';

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سند',
      many: '$count سندًا',
      few: '$count سندات',
      two: 'سندان',
      one: 'سند واحد',
    );
    return '$_temp0';
  }

  @override
  String get unitCartonHint =>
      'للكراتين والقطع المنفردة: اختر الوحدة (برطمان أو قطعة) واكتب كم قطعة في الكرتونة. عند التحميل والإغلاق تدخل الكراتين والقطع بشكل منفصل.';

  @override
  String get companyIncomplete =>
      'بيانات شركتك غير مكتملة. للفواتير تحتاج اسم الشركة والعنوان والرقم الضريبي أو رقم ضريبة القيمة المضافة.';

  @override
  String get fillCompany => 'املأ الآن';

  @override
  String get platform => 'إدارة الشركات';

  @override
  String get platformHint =>
      'بصفتك المدير العام تضيف مديرين مع شركة خاصة لكل منهم، وتحظر الشركات أو تحذفها نهائيًا.';

  @override
  String get userForMyCompany => 'إلى شركتي';

  @override
  String get userNewCompany => 'شركة جديدة';

  @override
  String get newCompanyUserHint =>
      'يحصل المستخدم على شركة جديدة خاصة به بكل الوظائف، ويصبح فيها المدير. لا يرى إلا بياناته، ولا ترى أنت شيئًا من شركته. أعطه كلمة المرور واطلب منه تغييرها بعد أول تسجيل دخول من الحساب. ثم يُدخل بنفسه عنوان شركته ورقمها الضريبي.';

  @override
  String get companyUserCreated => 'تم إنشاء الشركة والمدير';

  @override
  String get noFirms => 'لا توجد شركات بعد.';

  @override
  String get blockFirm => 'حظر الشركة';

  @override
  String get unblockFirm => 'رفع الحظر عن الشركة';

  @override
  String get firmBlocked => 'محظورة';

  @override
  String get deleteFirm => 'حذف الشركة نهائيًا';

  @override
  String deleteFirmMessage(String name) {
    return 'ستُحذف كل بيانات الشركة «$name» وملفاتها ومستخدميها نهائيًا. لا يمكن التراجع عن ذلك.';
  }

  @override
  String get typeNameToConfirm => 'اكتب اسم الشركة للتأكيد';

  @override
  String get deleteFirmConfirm => 'حذف نهائي';

  @override
  String get firmDeleted => 'تم حذف الشركة';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستخدمًا',
      few: '$count مستخدمين',
      two: 'مستخدمان',
      one: 'مستخدم واحد',
    );
    return '$_temp0';
  }

  @override
  String get accessBlocked => 'تم حظر وصولك. يرجى التواصل مع المشغّل.';

  @override
  String get nameGerman => 'الاسم (بالألمانية)';

  @override
  String get nameArabic => 'الاسم (بالعربية)';

  @override
  String get nameRequired => 'يلزم اسم واحد على الأقل.';

  @override
  String get nameHint =>
      'يمكنك الألمانية والعربية معًا، ويكفي اسم واحد. يعرض التطبيق الاسم بلغة الواجهة.';

  @override
  String get cartonContents => 'محتوى الكرتونة';

  @override
  String get cartonContentsHint =>
      'أي المنتجات وبأي كمية داخل الكرتونة. يمكنك إضافة منتجات أو حذفها وتغيير الكميات.';

  @override
  String get noContents => 'لا يوجد محتوى بعد.';

  @override
  String get cartonRemovalsTitle => 'منتجات منفردة من الكرتونة';

  @override
  String get cartonRemovalsHint =>
      'ما يعود أو يُهدى بشكل منفرد من هذه الكرتونة. ينقص الإيراد بسعر بيع هذه المنتجات.';

  @override
  String get removedGift => 'مُهدى';

  @override
  String get removalTooMany =>
      'عدد المنتجات المنفردة المسحوبة أكبر مما في الكراتين.';

  @override
  String get soldGoods => 'البضاعة المباعة';

  @override
  String get returnedGoods => 'البضاعة المُرجَعة';

  @override
  String get shareGoodsPdf => 'مشاركة كملف PDF';

  @override
  String get noGoods => 'لا توجد بضاعة.';

  @override
  String get goodsTotal => 'السعر الإجمالي';

  @override
  String removalLabel(String content, String carton) {
    return '$content (من $carton)';
  }

  @override
  String get tourSummaryPdf => 'تسوية الجولة كملف PDF';

  @override
  String get navDeliveryNote => 'التسليم';

  @override
  String get navInvoice => 'الفواتير';

  @override
  String get companySignature => 'توقيع الشركة';

  @override
  String signatureSize(int percent) {
    return 'حجم التوقيع في ملف PDF: $percent٪';
  }

  @override
  String get signatureSmaller => 'أصغر';

  @override
  String get signatureLarger => 'أكبر';

  @override
  String get companySignatureNone => 'لم يتم حفظ توقيع بعد.';

  @override
  String get companySignatureDraw => 'ارسم التوقيع';

  @override
  String get companySignatureRedraw => 'ارسم توقيعًا جديدًا';

  @override
  String get companySignatureDelete => 'حذف التوقيع';

  @override
  String get companySignatureSaved => 'تم حفظ التوقيع';

  @override
  String get companySignatureDeleted => 'تم حذف التوقيع';

  @override
  String get signatureClear => 'ابدأ من جديد';

  @override
  String get signatureOnDeliveryNote => 'الطباعة على إشعار التسليم';

  @override
  String get signatureOnInvoice => 'الطباعة على الفاتورة';

  @override
  String closeReturnHint(String unit, String max) {
    return 'المرتجع بوحدة $unit · الحد الأقصى $max';
  }

  @override
  String closeGiftHint(String unit, String max) {
    return 'الهدايا بوحدة $unit · الحد الأقصى $max';
  }

  @override
  String cartonContains(String items) {
    return 'الكرتونة الواحدة تحتوي على: $items';
  }

  @override
  String get soldResult => 'المباع';

  @override
  String get closeStepLoad => '١ · إرجاع البضاعة';

  @override
  String get closeStepGifts => '٢ · الهدايا';

  @override
  String get closeStepExpenses => '٣ · المصاريف';

  @override
  String get closeStepCash => '٤ · النقد والتسوية';

  @override
  String get closeInfoNew =>
      'اضغط «إرجاع بضاعة» واختر كرتونة أو منتجًا. كل ما لا يعود يُحسب كمباع.';

  @override
  String get takeOutAdd => 'إرجاع بضاعة';

  @override
  String get takeOutPick => 'ما الذي عاد؟';

  @override
  String get takeOutWhole => 'كرتونة كاملة';

  @override
  String get takeOutSingles => 'منتجات فردية';

  @override
  String get takeOutSinglesHint => 'كم من كل منتج يعود من الكرتونة أو يُهدى؟';

  @override
  String get takeOutNone => 'لم يُرجع شيء بعد. كل شيء يُحسب كمباع.';

  @override
  String deleteManyTitle(int count) {
    return 'حذف $count؟';
  }

  @override
  String get confirmDeleteMany =>
      'سيتم حذف العناصر المحددة نهائيًا ولا يمكن التراجع عن ذلك.';

  @override
  String get confirmDeleteManyInvoices =>
      'يجب الاحتفاظ بالفواتير المثبّتة 8 سنوات في ألمانيا. ستفقد أرقامها بعد الحذف.';

  @override
  String deletedMany(int count) {
    return 'تم حذف $count';
  }

  @override
  String deleteManyFailed(int count) {
    return 'تعذّر حذف $count.';
  }

  @override
  String get pdfNothingSelected => 'اختر عنصرًا واحدًا على الأقل أولًا.';

  @override
  String get pdfNothingToShow => 'لا يوجد شيء بعد لإنشاء ملف PDF.';

  @override
  String get pdfPleaseWait => 'انتظر قليلًا، ملف PDF ما زال قيد التحميل.';

  @override
  String get nothingToShare =>
      'لا يوجد ملف PDF لهذا العنصر. في الجولات فقط المكتملة.';

  @override
  String get pdfNoPreview =>
      'تعذّر عرض المعاينة. ما زال بإمكانك المشاركة والطباعة.';
}
