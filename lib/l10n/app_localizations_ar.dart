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

  @override
  String get app_settings_title => 'الإعدادات';

  @override
  String get app_language_label => 'اللغة';

  @override
  String get app_language_ar => 'العربية';

  @override
  String get app_language_en => 'الإنجليزية';

  @override
  String get app_theme_label => 'الثيم';

  @override
  String get theme_light => 'فاتح';

  @override
  String get theme_dark => 'داكن';

  @override
  String get theme_blue => 'أزرق';

  @override
  String get theme_purple => 'بنفسجي';

  @override
  String get theme_teal => 'فيروزي';

  @override
  String get theme_orange => 'برتقالي';

  @override
  String get theme_pink => 'وردي';

  @override
  String get theme_indigo => 'نيلي';

  @override
  String get theme_coral => 'كورال';

  @override
  String get theme_yellow => 'أصفر';

  @override
  String get item_options_title => 'خيارات الملف';

  @override
  String get action_set_as_cover => 'تعيين كغلاف';

  @override
  String get action_rename => 'إعادة تسمية';

  @override
  String get action_delete => 'حذف';

  @override
  String get action_cancel => 'إلغاء';

  @override
  String get snackbar_cover_set => 'تم تعيين صورة الغلاف';

  @override
  String get snackbar_rename_done => 'تم تغيير الاسم';

  @override
  String get snackbar_item_deleted => 'تم حذف العنصر';

  @override
  String get cover_badge => 'صورة غلاف';

  @override
  String get cover_none => 'بدون صورة غلاف';

  @override
  String get cover_set => 'تم تعيين صورة غلاف';

  @override
  String get cover_not_set => 'لم يتم تعيين صورة غلاف بعد';
}
