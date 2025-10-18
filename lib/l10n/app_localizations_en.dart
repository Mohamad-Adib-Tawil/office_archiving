// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Office Archiving';

  @override
  String get splashMessage => 'Make Your Files Archived';

  @override
  String get emptySectionsMessage =>
      'No sections yet. Tap + to add the first section.';

  @override
  String get emptyItemsMessage => 'No items in this section yet';

  @override
  String get optionsTitle => 'Options of the section';

  @override
  String get editName => 'Edit name';

  @override
  String get deleteSection => 'Delete the section';

  @override
  String get cancel => 'Cancel';

  @override
  String get searchItemsTitle => 'Search Items';

  @override
  String get searchLabel => 'Search';

  @override
  String get noItemsFound => 'No items found.';

  @override
  String get fileErrorTitle => 'File Error';

  @override
  String get fileErrorBody => 'File is missing or invalid';

  @override
  String get sectionNameRequired => 'Section name is required';

  @override
  String get addSectionTitle => 'Add Section';

  @override
  String get sectionNameLabel => 'Section name';

  @override
  String get addAction => 'Add';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get renameItemTitle => 'Rename item';

  @override
  String get newNameLabel => 'New name';

  @override
  String get renameAction => 'Rename';

  @override
  String get app_settings_title => 'Settings';

  @override
  String get app_language_label => 'Language';

  @override
  String get app_language_ar => 'Arabic';

  @override
  String get app_language_en => 'English';

  @override
  String get app_theme_label => 'Theme';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_blue => 'Blue';

  @override
  String get theme_purple => 'Purple';

  @override
  String get theme_teal => 'Teal';

  @override
  String get theme_orange => 'Orange';

  @override
  String get theme_pink => 'Pink';

  @override
  String get theme_indigo => 'Indigo';

  @override
  String get theme_coral => 'Coral';

  @override
  String get theme_yellow => 'Yellow';

  @override
  String get item_options_title => 'File Options';

  @override
  String get action_set_as_cover => 'Set as Cover';

  @override
  String get action_rename => 'Rename';

  @override
  String get action_delete => 'Delete';

  @override
  String get action_cancel => 'Cancel';

  @override
  String get snackbar_cover_set => 'Cover image set';

  @override
  String get snackbar_rename_done => 'Name changed';

  @override
  String get snackbar_item_deleted => 'Item deleted';

  @override
  String get cover_badge => 'Cover';

  @override
  String get cover_none => 'No cover';

  @override
  String get cover_set => 'Cover image set';

  @override
  String get cover_not_set => 'No cover image yet';
}
