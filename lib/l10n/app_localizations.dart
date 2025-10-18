import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Office Archiving'**
  String get appTitle;

  /// No description provided for @splashMessage.
  ///
  /// In en, this message translates to:
  /// **'Make Your Files Archived'**
  String get splashMessage;

  /// No description provided for @emptySectionsMessage.
  ///
  /// In en, this message translates to:
  /// **'No sections yet. Tap + to add the first section.'**
  String get emptySectionsMessage;

  /// No description provided for @emptyItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No items in this section yet'**
  String get emptyItemsMessage;

  /// No description provided for @optionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options of the section'**
  String get optionsTitle;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @deleteSection.
  ///
  /// In en, this message translates to:
  /// **'Delete the section'**
  String get deleteSection;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @searchItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Items'**
  String get searchItemsTitle;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found.'**
  String get noItemsFound;

  /// No description provided for @fileErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'File Error'**
  String get fileErrorTitle;

  /// No description provided for @fileErrorBody.
  ///
  /// In en, this message translates to:
  /// **'File is missing or invalid'**
  String get fileErrorBody;

  /// No description provided for @sectionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Section name is required'**
  String get sectionNameRequired;

  /// No description provided for @addSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSectionTitle;

  /// No description provided for @sectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get sectionNameLabel;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @renameItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename item'**
  String get renameItemTitle;

  /// No description provided for @newNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newNameLabel;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @app_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get app_settings_title;

  /// No description provided for @app_language_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get app_language_label;

  /// No description provided for @app_language_ar.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get app_language_ar;

  /// No description provided for @app_language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get app_language_en;

  /// No description provided for @app_theme_label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get app_theme_label;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get theme_blue;

  /// No description provided for @theme_purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get theme_purple;

  /// No description provided for @theme_teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get theme_teal;

  /// No description provided for @theme_orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get theme_orange;

  /// No description provided for @theme_pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get theme_pink;

  /// No description provided for @theme_indigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get theme_indigo;

  /// No description provided for @theme_coral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get theme_coral;

  /// No description provided for @theme_yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get theme_yellow;

  /// No description provided for @item_options_title.
  ///
  /// In en, this message translates to:
  /// **'File Options'**
  String get item_options_title;

  /// No description provided for @action_set_as_cover.
  ///
  /// In en, this message translates to:
  /// **'Set as Cover'**
  String get action_set_as_cover;

  /// No description provided for @action_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get action_rename;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @snackbar_cover_set.
  ///
  /// In en, this message translates to:
  /// **'Cover image set'**
  String get snackbar_cover_set;

  /// No description provided for @snackbar_rename_done.
  ///
  /// In en, this message translates to:
  /// **'Name changed'**
  String get snackbar_rename_done;

  /// No description provided for @snackbar_item_deleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get snackbar_item_deleted;

  /// No description provided for @cover_badge.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover_badge;

  /// No description provided for @cover_none.
  ///
  /// In en, this message translates to:
  /// **'No cover'**
  String get cover_none;

  /// No description provided for @cover_set.
  ///
  /// In en, this message translates to:
  /// **'Cover image set'**
  String get cover_set;

  /// No description provided for @cover_not_set.
  ///
  /// In en, this message translates to:
  /// **'No cover image yet'**
  String get cover_not_set;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
