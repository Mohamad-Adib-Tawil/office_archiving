// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أرشفة المكتب';

  @override
  String get splashMessage => 'أرشِف ملفاتك';

  @override
  String get emptySectionsMessage =>
      'لا توجد أقسام بعد. اضغط على زر + لإضافة أول قسم.';

  @override
  String get emptyItemsMessage => 'لا توجد عناصر بعد في هذا القسم';

  @override
  String get optionsTitle => 'خيارات القسم';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get deleteSection => 'حذف القسم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get searchItemsTitle => 'بحث عن العناصر';

  @override
  String get searchLabel => 'بحث';

  @override
  String get noItemsFound => 'لا توجد عناصر.';

  @override
  String get fileErrorTitle => 'خطأ في الملف';

  @override
  String get fileErrorBody => 'الملف مفقود أو غير صالح';

  @override
  String get sectionNameRequired => 'اسم القسم مطلوب';

  @override
  String get addSectionTitle => 'إضافة قسم';

  @override
  String get sectionNameLabel => 'اسم القسم';

  @override
  String get addAction => 'إضافة';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get renameItemTitle => 'إعادة تسمية العنصر';

  @override
  String get newNameLabel => 'الاسم الجديد';

  @override
  String get renameAction => 'إعادة تسمية';
}
