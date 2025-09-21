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
}
