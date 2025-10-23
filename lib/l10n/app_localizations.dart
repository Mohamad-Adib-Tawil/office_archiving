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
    Locale('en'),
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

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get theme_system;

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

  /// No description provided for @snackbar_cover_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cover image cleared'**
  String get snackbar_cover_cleared;

  /// No description provided for @settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_tooltip;

  /// No description provided for @empty_sections_message.
  ///
  /// In en, this message translates to:
  /// **'No sections yet'**
  String get empty_sections_message;

  /// No description provided for @loading_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get loading_error;

  /// No description provided for @storage_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to open file'**
  String get storage_permission_required;

  /// No description provided for @file_open_error.
  ///
  /// In en, this message translates to:
  /// **'Error opening file'**
  String get file_open_error;

  /// No description provided for @generic_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get generic_error;

  /// No description provided for @no_file_selected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get no_file_selected;

  /// No description provided for @permission_files_required.
  ///
  /// In en, this message translates to:
  /// **'File access permission required'**
  String get permission_files_required;

  /// No description provided for @no_image_picked.
  ///
  /// In en, this message translates to:
  /// **'No image picked'**
  String get no_image_picked;

  /// No description provided for @no_image_selected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get no_image_selected;

  /// No description provided for @rename_section_title.
  ///
  /// In en, this message translates to:
  /// **'Rename Section'**
  String get rename_section_title;

  /// No description provided for @new_name_label.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get new_name_label;

  /// No description provided for @set_cover_image.
  ///
  /// In en, this message translates to:
  /// **'Set Cover Image'**
  String get set_cover_image;

  /// No description provided for @clear_cover.
  ///
  /// In en, this message translates to:
  /// **'Clear Cover'**
  String get clear_cover;

  /// No description provided for @unknown_file_type.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get unknown_file_type;

  /// No description provided for @add_item_title.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get add_item_title;

  /// No description provided for @add_item_from_memory.
  ///
  /// In en, this message translates to:
  /// **'Add Item from Memory Storage'**
  String get add_item_from_memory;

  /// No description provided for @add_item_from_camera.
  ///
  /// In en, this message translates to:
  /// **'Add Item from Camera'**
  String get add_item_from_camera;

  /// No description provided for @add_item_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Add Item from Gallery'**
  String get add_item_from_gallery;

  /// No description provided for @from_files.
  ///
  /// In en, this message translates to:
  /// **'From Files'**
  String get from_files;

  /// No description provided for @from_gallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get from_gallery;

  /// No description provided for @from_camera.
  ///
  /// In en, this message translates to:
  /// **'From Camera'**
  String get from_camera;

  /// No description provided for @section_name_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter section name'**
  String get section_name_empty;

  /// No description provided for @section_name_exists.
  ///
  /// In en, this message translates to:
  /// **'Section name already exists'**
  String get section_name_exists;

  /// No description provided for @theme_ocean_blue.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get theme_ocean_blue;

  /// No description provided for @theme_sunset_orange.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get theme_sunset_orange;

  /// No description provided for @theme_forest_green.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get theme_forest_green;

  /// No description provided for @theme_royal_purple.
  ///
  /// In en, this message translates to:
  /// **'Royal Purple'**
  String get theme_royal_purple;

  /// No description provided for @theme_rose_gold.
  ///
  /// In en, this message translates to:
  /// **'Rose Gold'**
  String get theme_rose_gold;

  /// No description provided for @file_cleanup_title.
  ///
  /// In en, this message translates to:
  /// **'File Cleanup'**
  String get file_cleanup_title;

  /// No description provided for @analytics_title.
  ///
  /// In en, this message translates to:
  /// **'Storage Analytics'**
  String get analytics_title;

  /// No description provided for @scan_files.
  ///
  /// In en, this message translates to:
  /// **'Scan Files'**
  String get scan_files;

  /// No description provided for @scan_description.
  ///
  /// In en, this message translates to:
  /// **'Search for duplicate, broken, and large files to improve performance and save space'**
  String get scan_description;

  /// No description provided for @start_scan.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get start_scan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @files_scanned.
  ///
  /// In en, this message translates to:
  /// **'files scanned'**
  String get files_scanned;

  /// No description provided for @scan_results.
  ///
  /// In en, this message translates to:
  /// **'Scan Results'**
  String get scan_results;

  /// No description provided for @duplicate_files.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Files'**
  String get duplicate_files;

  /// No description provided for @broken_files.
  ///
  /// In en, this message translates to:
  /// **'Broken Files'**
  String get broken_files;

  /// No description provided for @large_files.
  ///
  /// In en, this message translates to:
  /// **'Large Files'**
  String get large_files;

  /// No description provided for @cleanup_actions.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Actions'**
  String get cleanup_actions;

  /// No description provided for @cleanup_options.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Options'**
  String get cleanup_options;

  /// No description provided for @remove_broken_files.
  ///
  /// In en, this message translates to:
  /// **'Remove Broken Files'**
  String get remove_broken_files;

  /// No description provided for @view_duplicate_files.
  ///
  /// In en, this message translates to:
  /// **'View Duplicate Files'**
  String get view_duplicate_files;

  /// No description provided for @view_large_files.
  ///
  /// In en, this message translates to:
  /// **'View Large Files'**
  String get view_large_files;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning...'**
  String get cleaning;

  /// No description provided for @auto_cleanup.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup'**
  String get auto_cleanup;

  /// No description provided for @space_saved.
  ///
  /// In en, this message translates to:
  /// **'Space saved'**
  String get space_saved;

  /// No description provided for @files_cleaned.
  ///
  /// In en, this message translates to:
  /// **'broken files cleaned'**
  String get files_cleaned;

  /// No description provided for @cleanup_error.
  ///
  /// In en, this message translates to:
  /// **'Cleanup error'**
  String get cleanup_error;

  /// No description provided for @scan_error.
  ///
  /// In en, this message translates to:
  /// **'Scan error'**
  String get scan_error;

  /// No description provided for @no_issues_found.
  ///
  /// In en, this message translates to:
  /// **'No issues found! Your files are well organized'**
  String get no_issues_found;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'copies'**
  String get copies;

  /// No description provided for @same_size_files.
  ///
  /// In en, this message translates to:
  /// **'Files with same size'**
  String get same_size_files;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get files;

  /// No description provided for @file_not_found.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get file_not_found;

  /// No description provided for @monthly_report.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthly_report;

  /// No description provided for @files_added.
  ///
  /// In en, this message translates to:
  /// **'Files Added'**
  String get files_added;

  /// No description provided for @space_used.
  ///
  /// In en, this message translates to:
  /// **'Space Used'**
  String get space_used;

  /// No description provided for @most_common_type.
  ///
  /// In en, this message translates to:
  /// **'Most Common Type'**
  String get most_common_type;

  /// No description provided for @growth_rate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate'**
  String get growth_rate;

  /// No description provided for @file_type_distribution.
  ///
  /// In en, this message translates to:
  /// **'File Type Distribution'**
  String get file_type_distribution;

  /// No description provided for @size_distribution.
  ///
  /// In en, this message translates to:
  /// **'Size Distribution'**
  String get size_distribution;

  /// No description provided for @weekly_usage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Usage'**
  String get weekly_usage;

  /// No description provided for @most_accessed_files.
  ///
  /// In en, this message translates to:
  /// **'Most Accessed Files'**
  String get most_accessed_files;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get no_data;

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get undefined;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutes_ago;

  /// No description provided for @hours_ago.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hours_ago;

  /// No description provided for @days_ago.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get days_ago;

  /// No description provided for @total_files.
  ///
  /// In en, this message translates to:
  /// **'Total Files'**
  String get total_files;

  /// No description provided for @sections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sections;

  /// No description provided for @storage_size.
  ///
  /// In en, this message translates to:
  /// **'Storage Size'**
  String get storage_size;

  /// No description provided for @avg_files_per_section.
  ///
  /// In en, this message translates to:
  /// **'Avg Files/Section'**
  String get avg_files_per_section;

  /// No description provided for @no_files_to_scan.
  ///
  /// In en, this message translates to:
  /// **'No files to scan'**
  String get no_files_to_scan;

  /// No description provided for @scan_completed_issues.
  ///
  /// In en, this message translates to:
  /// **'Scan completed! Found {count} issues'**
  String scan_completed_issues(Object count);

  /// No description provided for @scan_completed_no_issues.
  ///
  /// In en, this message translates to:
  /// **'Scan completed successfully! No issues found'**
  String get scan_completed_no_issues;

  /// No description provided for @space_analyzed.
  ///
  /// In en, this message translates to:
  /// **'Space analyzed'**
  String get space_analyzed;

  /// No description provided for @starting_scan.
  ///
  /// In en, this message translates to:
  /// **'Starting scan...'**
  String get starting_scan;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @and_more_items.
  ///
  /// In en, this message translates to:
  /// **'and {count} more items...'**
  String and_more_items(Object count);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @keepAction.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keepAction;

  /// No description provided for @choose_image_source.
  ///
  /// In en, this message translates to:
  /// **'Choose image source'**
  String get choose_image_source;

  /// No description provided for @snack_extraction_done.
  ///
  /// In en, this message translates to:
  /// **'Text extracted successfully!'**
  String get snack_extraction_done;

  /// No description provided for @snack_translation_done.
  ///
  /// In en, this message translates to:
  /// **'Text translated successfully!'**
  String get snack_translation_done;

  /// No description provided for @snack_summary_done.
  ///
  /// In en, this message translates to:
  /// **'Text summarized successfully!'**
  String get snack_summary_done;

  /// No description provided for @snack_copy_done.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get snack_copy_done;

  /// No description provided for @copy_action.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy_action;

  /// No description provided for @ai_features_title.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get ai_features_title;

  /// No description provided for @ai_extract_title.
  ///
  /// In en, this message translates to:
  /// **'Extract text from images'**
  String get ai_extract_title;

  /// No description provided for @ai_extract_desc.
  ///
  /// In en, this message translates to:
  /// **'Convert images into editable text'**
  String get ai_extract_desc;

  /// No description provided for @ai_extracted_text_title.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get ai_extracted_text_title;

  /// No description provided for @ai_translate_action.
  ///
  /// In en, this message translates to:
  /// **'Translate text'**
  String get ai_translate_action;

  /// No description provided for @ai_summary_action.
  ///
  /// In en, this message translates to:
  /// **'Summarize text'**
  String get ai_summary_action;

  /// No description provided for @ai_translated_text_title.
  ///
  /// In en, this message translates to:
  /// **'Translated text'**
  String get ai_translated_text_title;

  /// No description provided for @ai_summary_text_title.
  ///
  /// In en, this message translates to:
  /// **'Text summary'**
  String get ai_summary_text_title;

  /// No description provided for @ai_features_list_title.
  ///
  /// In en, this message translates to:
  /// **'Available AI features'**
  String get ai_features_list_title;

  /// No description provided for @ai_feature_extract_title.
  ///
  /// In en, this message translates to:
  /// **'📷 Extract text from images'**
  String get ai_feature_extract_title;

  /// No description provided for @ai_feature_extract_desc.
  ///
  /// In en, this message translates to:
  /// **'Convert scanned images and documents into editable text'**
  String get ai_feature_extract_desc;

  /// No description provided for @ai_feature_translate_title.
  ///
  /// In en, this message translates to:
  /// **'🌐 Translate documents'**
  String get ai_feature_translate_title;

  /// No description provided for @ai_feature_translate_desc.
  ///
  /// In en, this message translates to:
  /// **'Automatically translate texts between Arabic and English'**
  String get ai_feature_translate_desc;

  /// No description provided for @ai_feature_summarize_title.
  ///
  /// In en, this message translates to:
  /// **'📝 Summarize documents'**
  String get ai_feature_summarize_title;

  /// No description provided for @ai_feature_summarize_desc.
  ///
  /// In en, this message translates to:
  /// **'Generate smart summaries for long texts'**
  String get ai_feature_summarize_desc;

  /// No description provided for @ai_feature_smart_organize_title.
  ///
  /// In en, this message translates to:
  /// **'🤖 Smart organization'**
  String get ai_feature_smart_organize_title;

  /// No description provided for @ai_feature_smart_organize_desc.
  ///
  /// In en, this message translates to:
  /// **'Automatic suggestions to classify and organize files'**
  String get ai_feature_smart_organize_desc;

  /// No description provided for @ai_feature_smart_search_title.
  ///
  /// In en, this message translates to:
  /// **'🔍 Smart search'**
  String get ai_feature_smart_search_title;

  /// No description provided for @ai_feature_smart_search_desc.
  ///
  /// In en, this message translates to:
  /// **'Search within file and image contents'**
  String get ai_feature_smart_search_desc;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get coming_soon;

  /// No description provided for @start_action.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_action;

  /// No description provided for @processing_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing_ellipsis;

  /// No description provided for @tooltip_scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get tooltip_scanner;

  /// No description provided for @tooltip_ai.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get tooltip_ai;

  /// No description provided for @tooltip_cleaner.
  ///
  /// In en, this message translates to:
  /// **'File Cleaner'**
  String get tooltip_cleaner;

  /// No description provided for @doc_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Document Management'**
  String get doc_manage_title;

  /// No description provided for @scan_document_action.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scan_document_action;

  /// No description provided for @create_pdf_action.
  ///
  /// In en, this message translates to:
  /// **'Create PDF'**
  String get create_pdf_action;

  /// No description provided for @digital_signature_action.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get digital_signature_action;

  /// No description provided for @merge_files_action.
  ///
  /// In en, this message translates to:
  /// **'Merge Files'**
  String get merge_files_action;

  /// No description provided for @tab_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get tab_images;

  /// No description provided for @tab_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tab_documents;

  /// No description provided for @tab_signatures.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get tab_signatures;

  /// No description provided for @empty_images.
  ///
  /// In en, this message translates to:
  /// **'No scanned images'**
  String get empty_images;

  /// No description provided for @empty_documents.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get empty_documents;

  /// No description provided for @empty_signatures.
  ///
  /// In en, this message translates to:
  /// **'No signatures'**
  String get empty_signatures;

  /// No description provided for @empty_hint_add_content.
  ///
  /// In en, this message translates to:
  /// **'Use the buttons above to add new content'**
  String get empty_hint_add_content;

  /// No description provided for @snack_document_added.
  ///
  /// In en, this message translates to:
  /// **'Document added successfully!'**
  String get snack_document_added;

  /// No description provided for @delete_document_title.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get delete_document_title;

  /// No description provided for @delete_document_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get delete_document_message;

  /// No description provided for @delete_signature_title.
  ///
  /// In en, this message translates to:
  /// **'Delete signature'**
  String get delete_signature_title;

  /// No description provided for @delete_signature_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this signature?'**
  String get delete_signature_message;

  /// No description provided for @snack_document_deleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get snack_document_deleted;

  /// No description provided for @snack_signature_deleted.
  ///
  /// In en, this message translates to:
  /// **'Signature deleted'**
  String get snack_signature_deleted;

  /// No description provided for @snack_pdf_created.
  ///
  /// In en, this message translates to:
  /// **'Document file created successfully!'**
  String get snack_pdf_created;

  /// No description provided for @error_merge_min_files.
  ///
  /// In en, this message translates to:
  /// **'At least two files are required to merge'**
  String get error_merge_min_files;

  /// No description provided for @snack_merge_success.
  ///
  /// In en, this message translates to:
  /// **'Files merged successfully!'**
  String get snack_merge_success;

  /// No description provided for @snack_watermark_added.
  ///
  /// In en, this message translates to:
  /// **'Watermark added successfully!'**
  String get snack_watermark_added;

  /// No description provided for @digital_signature_title.
  ///
  /// In en, this message translates to:
  /// **'Create Digital Signature'**
  String get digital_signature_title;

  /// No description provided for @enter_signature_text.
  ///
  /// In en, this message translates to:
  /// **'Enter signature text:'**
  String get enter_signature_text;

  /// No description provided for @signature_hint_example.
  ///
  /// In en, this message translates to:
  /// **'Example: John Doe'**
  String get signature_hint_example;

  /// No description provided for @create_action.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create_action;

  /// No description provided for @document_n.
  ///
  /// In en, this message translates to:
  /// **'Document {n}'**
  String document_n(Object n);

  /// No description provided for @signature_n.
  ///
  /// In en, this message translates to:
  /// **'Signature {n}'**
  String signature_n(Object n);

  /// No description provided for @view_action.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view_action;

  /// No description provided for @share_action.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share_action;

  /// No description provided for @watermark_action.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get watermark_action;

  /// No description provided for @view_document_title.
  ///
  /// In en, this message translates to:
  /// **'View Document'**
  String get view_document_title;

  /// No description provided for @view_file_title.
  ///
  /// In en, this message translates to:
  /// **'View {name}'**
  String view_file_title(Object name);

  /// No description provided for @share_prepared_prefix.
  ///
  /// In en, this message translates to:
  /// **'File prepared for sharing:'**
  String get share_prepared_prefix;

  /// No description provided for @file_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get file_size;

  /// No description provided for @file_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get file_date;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'since'**
  String get since;
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
    'that was used.',
  );
}
