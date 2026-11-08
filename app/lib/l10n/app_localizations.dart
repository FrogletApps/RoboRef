import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Production application title
  ///
  /// In en, this message translates to:
  /// **'RoboRef'**
  String get appTitle;

  /// Local development application title
  ///
  /// In en, this message translates to:
  /// **'RoboRef Local'**
  String get appTitleLocal;

  /// Test environment application title
  ///
  /// In en, this message translates to:
  /// **'RoboRef Test'**
  String get appTitleTest;

  /// Badge label for local environment
  ///
  /// In en, this message translates to:
  /// **'LOCAL'**
  String get envBadgeLocal;

  /// Badge label for test environment
  ///
  /// In en, this message translates to:
  /// **'TEST'**
  String get envBadgeTest;

  /// Badge label for release version
  ///
  /// In en, this message translates to:
  /// **'RELEASE'**
  String get envBadgeRelease;

  /// Filter chip label for showing all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// Standard cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Standard close button or tooltip label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Standard retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Standard delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Standard remove button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Standard copy button label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Standard OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Standard enable button label
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonEnable;

  /// Tooltip and button label to clear a search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// Button label to clear all selected items
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get commonClearAll;

  /// Done button showing count of selected items
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String commonDoneCount(int count);

  /// Button label to add a new incident note
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get commonAddNote;

  /// Button label to save an incident note
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get commonSaveNote;

  /// Button or menu item to share an event online
  ///
  /// In en, this message translates to:
  /// **'Share Event Online'**
  String get commonShareEventOnline;

  /// Default display name for the head referee
  ///
  /// In en, this message translates to:
  /// **'Head Referee'**
  String get commonHeadReferee;

  /// Default fallback name for a referee participant
  ///
  /// In en, this message translates to:
  /// **'Referee'**
  String get commonReferee;

  /// Category label for custom user-entered rule codes
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get commonCustom;

  /// Snackbar message when an external URL cannot be launched
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {url}'**
  String commonCouldNotOpenLink(String url);

  /// Snackbar message when a link is copied to the clipboard as fallback
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard: {url}'**
  String commonLinkCopiedToClipboard(String url);

  /// Display name for the official RoboRef cloud sync server
  ///
  /// In en, this message translates to:
  /// **'RoboRef Cloud Server'**
  String get commonServerTypeCloud;

  /// Display name for a custom or local LAN sync server
  ///
  /// In en, this message translates to:
  /// **'Other Server'**
  String get commonServerTypeOther;

  /// Section header for recent tournaments on the home screen
  ///
  /// In en, this message translates to:
  /// **'Recent Tournaments'**
  String get homeRecentTournaments;

  /// Badge showing which server type an event is being shared on
  ///
  /// In en, this message translates to:
  /// **'Sharing: {serverType}'**
  String homeSharingLabel(String serverType);

  /// Snackbar message when an event is hidden from the recent list
  ///
  /// In en, this message translates to:
  /// **'Removed {sku} from recent list'**
  String homeRemovedFromRecent(String sku);

  /// Menu item to remove an event from the recent list
  ///
  /// In en, this message translates to:
  /// **'Remove from recent'**
  String get homeRemoveFromRecent;

  /// Quick action button and screen title for sharing the RoboRef app
  ///
  /// In en, this message translates to:
  /// **'Share RoboRef'**
  String get homeShareRoboRef;

  /// Quick action button and screen title for app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// Primary button on the home screen to select or add a tournament
  ///
  /// In en, this message translates to:
  /// **'Add a new event'**
  String get homeAddNewEvent;

  /// Heading on the welcome card when no events have been added
  ///
  /// In en, this message translates to:
  /// **'Welcome to RoboRef!'**
  String get homeWelcomeTitle;

  /// Description text on the home welcome card
  ///
  /// In en, this message translates to:
  /// **'This is an anomaly log for Head Referees at VEX robotics competitions.'**
  String get homeWelcomeDescription;

  /// Onboarding instruction on the home welcome card
  ///
  /// In en, this message translates to:
  /// **'To get started, tap the \"Add a new event\" button above.'**
  String get homeWelcomeInstruction;

  /// AppBar title on the Share RoboRef screen
  ///
  /// In en, this message translates to:
  /// **'Share RoboRef'**
  String get shareTitle;

  /// Instruction text above the QR code on the Share RoboRef screen
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code below or share the link with head referees, alliance referees, and scorekeepers.'**
  String get shareDescription;

  /// Snackbar message when the RoboRef app URL is copied
  ///
  /// In en, this message translates to:
  /// **'RoboRef link copied to clipboard!'**
  String get shareLinkCopied;

  /// Button label to copy the RoboRef app link
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get shareCopyLink;

  /// AppBar title and settings item for the Change Log screen
  ///
  /// In en, this message translates to:
  /// **'Change Log'**
  String get changelogTitle;

  /// Tooltip for reloading the changelog
  ///
  /// In en, this message translates to:
  /// **'Reload Changelog'**
  String get changelogReloadTooltip;

  /// Loading indicator text on the Change Log screen
  ///
  /// In en, this message translates to:
  /// **'Loading changelog...'**
  String get changelogLoading;

  /// Error heading when the changelog markdown fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load change log'**
  String get changelogUnableToLoad;

  /// Section header above changelog release cards
  ///
  /// In en, this message translates to:
  /// **'Release History'**
  String get changelogReleaseHistory;

  /// Fallback release card title when markdown has no headings
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get changelogReleaseNotesFallback;

  /// Hint text for searching the changelog
  ///
  /// In en, this message translates to:
  /// **'Search release notes...'**
  String get changelogSearchHint;

  /// Empty state text when no changelog entries match the search query
  ///
  /// In en, this message translates to:
  /// **'No changelog entries found matching \"{query}\"'**
  String changelogNoEntriesMatching(String query);

  /// Snackbar message when a markdown link in the changelog is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied: {href}'**
  String changelogLinkCopied(String href);

  /// AppBar title on the event selection screen
  ///
  /// In en, this message translates to:
  /// **'Pick An Event'**
  String get eventSelectionTitle;

  /// Tooltip for the reload events button
  ///
  /// In en, this message translates to:
  /// **'Reload Events'**
  String get eventSelectionReloadTooltip;

  /// Search field hint on the event selection screen
  ///
  /// In en, this message translates to:
  /// **'Search by SKU (RE-... / VE-...) or event name'**
  String get eventSelectionSearchHint;

  /// Filter chip and list item label for all regions
  ///
  /// In en, this message translates to:
  /// **'All Regions'**
  String get eventSelectionAllRegions;

  /// Filter chip label when a specific region is selected
  ///
  /// In en, this message translates to:
  /// **'Region: {region}'**
  String eventSelectionRegionSelected(String region);

  /// Filter chip and list item label for all US states
  ///
  /// In en, this message translates to:
  /// **'All States'**
  String get eventSelectionAllStates;

  /// Filter chip and list item label for all Canadian provinces
  ///
  /// In en, this message translates to:
  /// **'All Provinces'**
  String get eventSelectionAllProvinces;

  /// Filter chip label when a US state is selected
  ///
  /// In en, this message translates to:
  /// **'State: {division}'**
  String eventSelectionStateSelected(String division);

  /// Filter chip label when a Canadian province is selected
  ///
  /// In en, this message translates to:
  /// **'Province: {division}'**
  String eventSelectionProvinceSelected(String division);

  /// Fallback filter label for all administrative divisions
  ///
  /// In en, this message translates to:
  /// **'All {pluralLabel}'**
  String eventSelectionAllDivisions(String pluralLabel);

  /// Fallback filter chip label when an administrative division is selected
  ///
  /// In en, this message translates to:
  /// **'{singularLabel}: {division}'**
  String eventSelectionDivisionSelected(String singularLabel, String division);

  /// Button label to reset active event filters
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get eventSelectionResetFilters;

  /// Subtitle on the custom SKU entry card
  ///
  /// In en, this message translates to:
  /// **'Add & fetch custom {program} tournament schedule'**
  String eventSelectionAddCustomSchedule(String program);

  /// Default tournament name when adding an event manually by SKU
  ///
  /// In en, this message translates to:
  /// **'{program} Tournament ({sku})'**
  String eventSelectionCustomTournamentName(String program, String sku);

  /// Button label on the custom SKU card
  ///
  /// In en, this message translates to:
  /// **'Add & Select'**
  String get eventSelectionAddAndSelect;

  /// Section header for the events list
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventSelectionEventsHeader;

  /// Summary count of events found in the active date window
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 event between {startDate} and {endDate}} other{Found {count} events between {startDate} and {endDate}}}'**
  String eventSelectionFoundEventsSummary(
      int count, String startDate, String endDate);

  /// Loading text when fetching events from the VEX Events API
  ///
  /// In en, this message translates to:
  /// **'Loading live events from VEX Events...'**
  String get eventSelectionLoadingEvents;

  /// Error message when the VEX Events proxy cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Could not connect to VEX Events proxy.'**
  String get eventSelectionProxyError;

  /// Empty state heading when no events match the current window and filters
  ///
  /// In en, this message translates to:
  /// **'No events found in this date window.'**
  String get eventSelectionNoEventsFound;

  /// Empty state subtitle on the event selection screen
  ///
  /// In en, this message translates to:
  /// **'Try loading a wider date range or entering a SKU directly.'**
  String get eventSelectionNoEventsSubtitle;

  /// Button to expand the event search window by 30 days
  ///
  /// In en, this message translates to:
  /// **'Search Next 30 Days'**
  String get eventSelectionSearchNext30Days;

  /// Button label while loading additional events
  ///
  /// In en, this message translates to:
  /// **'Loading More Events...'**
  String get eventSelectionLoadingMoreEvents;

  /// Button label to load more events
  ///
  /// In en, this message translates to:
  /// **'Load More Events'**
  String get eventSelectionLoadMoreEvents;

  /// Snackbar message when offline reload falls back to cached events
  ///
  /// In en, this message translates to:
  /// **'Could not reach server. Showing cached events.'**
  String get eventSelectionShowingCachedEvents;

  /// Snackbar message shown when an event is selected and data is being fetched
  ///
  /// In en, this message translates to:
  /// **'Loading teams and match schedule for {sku}...'**
  String eventSelectionLoadingTournamentData(String sku);

  /// Snackbar message shown after tournament teams and matches finish loading
  ///
  /// In en, this message translates to:
  /// **'Loaded \"{eventName}\" ({teamsCount, plural, =1{1 team} other{{teamsCount} teams}}, {matchesCount, plural, =1{1 match} other{{matchesCount} matches}})'**
  String eventSelectionLoadedTournamentSummary(
      String eventName, int teamsCount, int matchesCount);

  /// Snackbar notice when loading tournament data returns a warning/error
  ///
  /// In en, this message translates to:
  /// **'Note: {errorMessage}'**
  String eventSelectionLoadNotePrefix(String errorMessage);

  /// Title of the region picker modal sheet
  ///
  /// In en, this message translates to:
  /// **'Filter by Region'**
  String get eventSelectionFilterByRegion;

  /// Search input hint inside the region picker modal
  ///
  /// In en, this message translates to:
  /// **'Search region (e.g. United States, UK, Australia)...'**
  String get eventSelectionSearchRegionHint;

  /// Empty state when no regions match the filter text
  ///
  /// In en, this message translates to:
  /// **'No regions matching \"{query}\"'**
  String eventSelectionNoRegionsMatching(String query);

  /// Subtitle showing matching states/provinces inside a region
  ///
  /// In en, this message translates to:
  /// **'Includes: {divisions}'**
  String eventSelectionRegionIncludes(String divisions);

  /// Title of the division picker sheet for US states
  ///
  /// In en, this message translates to:
  /// **'Filter by State'**
  String get eventSelectionFilterByState;

  /// Title of the division picker sheet for Canadian provinces
  ///
  /// In en, this message translates to:
  /// **'Filter by Province'**
  String get eventSelectionFilterByProvince;

  /// Fallback title of the division picker sheet
  ///
  /// In en, this message translates to:
  /// **'Filter by {singularLabel}'**
  String eventSelectionFilterByDivision(String singularLabel);

  /// Search hint for US states
  ///
  /// In en, this message translates to:
  /// **'Search states (e.g. Texas, TX)...'**
  String get eventSelectionSearchStatesHint;

  /// Search hint for Canadian provinces
  ///
  /// In en, this message translates to:
  /// **'Search provinces (e.g. Texas, TX)...'**
  String get eventSelectionSearchProvincesHint;

  /// Fallback search hint for divisions
  ///
  /// In en, this message translates to:
  /// **'Search {pluralLabelLower} (e.g. Texas, TX)...'**
  String eventSelectionSearchDivisionsHint(String pluralLabelLower);

  /// Empty state when no US states match the search query
  ///
  /// In en, this message translates to:
  /// **'No states matching \"{query}\"'**
  String eventSelectionNoStatesMatching(String query);

  /// Empty state when no Canadian provinces match the search query
  ///
  /// In en, this message translates to:
  /// **'No provinces matching \"{query}\"'**
  String eventSelectionNoProvincesMatching(String query);

  /// Fallback empty state when no divisions match the search query
  ///
  /// In en, this message translates to:
  /// **'No {pluralLabelLower} matching \"{query}\"'**
  String eventSelectionNoDivisionsMatching(
      String pluralLabelLower, String query);

  /// AppBar title for the Match Schedule tab
  ///
  /// In en, this message translates to:
  /// **'Match Schedule'**
  String get workspaceTitleMatchSchedule;

  /// AppBar title for the Team Histories tab
  ///
  /// In en, this message translates to:
  /// **'Team Histories'**
  String get workspaceTitleTeamHistories;

  /// AppBar title for the Incident Notes tab
  ///
  /// In en, this message translates to:
  /// **'RoboRef'**
  String get workspaceTitleNotes;

  /// AppBar title for the Game Rules Summary tab
  ///
  /// In en, this message translates to:
  /// **'Game Rules Summary'**
  String get workspaceTitleRules;

  /// AppBar title for the Manage & Sync tab
  ///
  /// In en, this message translates to:
  /// **'Manage & Sync'**
  String get workspaceTitleManage;

  /// Bottom navigation label for the Matches tab
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get workspaceNavMatches;

  /// Bottom navigation label for the Teams tab
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get workspaceNavTeams;

  /// Bottom navigation label for the Notes tab
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workspaceNavNotes;

  /// Bottom navigation label for the Rules tab
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get workspaceNavRules;

  /// Bottom navigation label for the Manage tab
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get workspaceNavManage;

  /// Tooltip for refreshing the match schedule
  ///
  /// In en, this message translates to:
  /// **'Refresh Matches'**
  String get workspaceRefreshMatchesTooltip;

  /// Tooltip for importing match schedule CSV
  ///
  /// In en, this message translates to:
  /// **'Load / Import Schedule'**
  String get workspaceImportScheduleTooltip;

  /// Tooltip for refreshing the team list
  ///
  /// In en, this message translates to:
  /// **'Refresh Teams'**
  String get workspaceRefreshTeamsTooltip;

  /// Tooltip for importing teams CSV
  ///
  /// In en, this message translates to:
  /// **'Load / Import Teams'**
  String get workspaceImportTeamsTooltip;

  /// Tooltip for syncing incident notes
  ///
  /// In en, this message translates to:
  /// **'Sync Notes'**
  String get workspaceSyncNotesTooltip;

  /// Tooltip on the share icon when the current referee is hosting an online session
  ///
  /// In en, this message translates to:
  /// **'Hosting Online ({count} connected)'**
  String workspaceHostingOnlineTooltip(int count);

  /// Tooltip on the share icon when connected as a participant
  ///
  /// In en, this message translates to:
  /// **'Connected Online ({count} connected)'**
  String workspaceConnectedOnlineTooltip(int count);

  /// Snackbar message when missing tournament matches are auto-fetched
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} match(es) for {sku}'**
  String workspaceLoadedMatchesForSku(int count, String sku);

  /// Snackbar message while checking for match updates
  ///
  /// In en, this message translates to:
  /// **'Checking for match schedule updates...'**
  String get workspaceCheckingMatchUpdates;

  /// Snackbar message when match schedule updates are fetched
  ///
  /// In en, this message translates to:
  /// **'Updated {count} match(es)'**
  String workspaceUpdatedMatches(int count);

  /// Snackbar message when no new matches were found
  ///
  /// In en, this message translates to:
  /// **'Match schedule is up to date'**
  String get workspaceMatchScheduleUpToDate;

  /// Fallback error message when updating matches fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update matches'**
  String get workspaceFailedToUpdateMatches;

  /// Snackbar message while checking for team roster updates
  ///
  /// In en, this message translates to:
  /// **'Checking for team roster updates...'**
  String get workspaceCheckingTeamUpdates;

  /// Snackbar message when team roster updates are fetched
  ///
  /// In en, this message translates to:
  /// **'Updated {count} team(s)'**
  String workspaceUpdatedTeams(int count);

  /// Snackbar message when the team list is already up to date
  ///
  /// In en, this message translates to:
  /// **'Team list is up to date'**
  String get workspaceTeamListUpToDate;

  /// Fallback error message when updating teams fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update teams'**
  String get workspaceFailedToUpdateTeams;

  /// Snackbar message when manual note sync is triggered from workspace
  ///
  /// In en, this message translates to:
  /// **'Syncing notes...'**
  String get workspaceSyncingNotes;

  /// Title of the CSV tournament data import bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Load Tournament Data'**
  String get eventImportTitle;

  /// Subtitle of the CSV tournament data import bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Paste Tournament Manager (TM) export data below.'**
  String get eventImportSubtitle;

  /// Segmented button label for importing Teams CSV
  ///
  /// In en, this message translates to:
  /// **'Teams CSV'**
  String get eventImportTeamsCsvTab;

  /// Segmented button label for importing Match Schedule CSV
  ///
  /// In en, this message translates to:
  /// **'Match Schedule CSV'**
  String get eventImportMatchesCsvTab;

  /// Input field label for pasting Teams CSV
  ///
  /// In en, this message translates to:
  /// **'Paste Teams CSV Text'**
  String get eventImportPasteTeamsLabel;

  /// Input field label for pasting Matches CSV
  ///
  /// In en, this message translates to:
  /// **'Paste Matches CSV Text'**
  String get eventImportPasteMatchesLabel;

  /// Example CSV hint for Teams import
  ///
  /// In en, this message translates to:
  /// **'Number, Name, City, State, Country\n1234A, RoboKnights, Austin, TX, USA'**
  String get eventImportPasteTeamsHint;

  /// Example CSV hint for Matches import
  ///
  /// In en, this message translates to:
  /// **'Match, Field, Time, Red 1, Red 2, Blue 1, Blue 2\nQ1, Field 1, 09:00, 1234A, 5678B, 9012C, 3456D'**
  String get eventImportPasteMatchesHint;

  /// Button label while CSV import is in progress
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get eventImportImportingButton;

  /// Button label to import Teams CSV
  ///
  /// In en, this message translates to:
  /// **'Import Teams CSV'**
  String get eventImportTeamsButton;

  /// Button label to import Matches CSV
  ///
  /// In en, this message translates to:
  /// **'Import Matches CSV'**
  String get eventImportMatchesButton;

  /// Validation error when attempting CSV import with no active SKU
  ///
  /// In en, this message translates to:
  /// **'No tournament SKU selected.'**
  String get eventImportNoSkuError;

  /// Validation error when CSV text field is empty
  ///
  /// In en, this message translates to:
  /// **'Please paste CSV content to import.'**
  String get eventImportEmptyCsvError;

  /// Status message after importing teams from CSV
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} teams!'**
  String eventImportTeamsSuccess(int count);

  /// Status message after importing matches from CSV
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} matches!'**
  String eventImportMatchesSuccess(int count);

  /// Search input hint on the Match Schedule screen
  ///
  /// In en, this message translates to:
  /// **'Search by match (e.g. Q12) or team...'**
  String get matchScheduleSearchHint;

  /// Error text when matches stream fails
  ///
  /// In en, this message translates to:
  /// **'Error loading matches: {error}'**
  String matchScheduleErrorLoading(String error);

  /// Empty state message when no matches are loaded for the tournament
  ///
  /// In en, this message translates to:
  /// **'No match schedule has been loaded yet.'**
  String get matchScheduleEmpty;

  /// Empty state message when no matches match the search query
  ///
  /// In en, this message translates to:
  /// **'No matches found matching \"{query}\"'**
  String matchScheduleNoMatchesMatching(String query);

  /// Button label while checking for a match schedule
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get matchScheduleCheckingButton;

  /// Button label to check for a match schedule
  ///
  /// In en, this message translates to:
  /// **'Check for Schedule'**
  String get matchScheduleCheckButton;

  /// Button label to open the import schedule sheet
  ///
  /// In en, this message translates to:
  /// **'Fetch or Import Schedule'**
  String get matchScheduleFetchOrImportButton;

  /// Badge label for single-alliance matches (e.g. VIQRC Teamwork)
  ///
  /// In en, this message translates to:
  /// **'TEAMS'**
  String get matchScheduleAllianceTeams;

  /// Badge label for the Red alliance
  ///
  /// In en, this message translates to:
  /// **'RED'**
  String get matchScheduleAllianceRed;

  /// Badge label for the Blue alliance
  ///
  /// In en, this message translates to:
  /// **'BLUE'**
  String get matchScheduleAllianceBlue;

  /// Message in the match details sheet when a match has no teams
  ///
  /// In en, this message translates to:
  /// **'No teams assigned to this match.'**
  String get matchScheduleNoTeamsAssigned;

  /// Label when a team has no incident notes logged
  ///
  /// In en, this message translates to:
  /// **'No notes logged'**
  String get matchScheduleNoNotesLogged;

  /// Full display name for a Practice match
  ///
  /// In en, this message translates to:
  /// **'Practice {num}'**
  String matchNamePractice(int num);

  /// Full display name for a Qualification match
  ///
  /// In en, this message translates to:
  /// **'Qualification {num}'**
  String matchNameQualification(int num);

  /// Full display name for an elimination/teamwork Finals match with instance and match number
  ///
  /// In en, this message translates to:
  /// **'Finals {instance}-{num}'**
  String matchNameFinalsInstance(int instance, int num);

  /// Full display name for a Finals match with a single match number
  ///
  /// In en, this message translates to:
  /// **'Finals {num}'**
  String matchNameFinals(int num);

  /// Search input hint on the Team Histories screen
  ///
  /// In en, this message translates to:
  /// **'Search teams...'**
  String get teamListSearchHint;

  /// Error message when teams or notes fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading teams: {error}'**
  String teamListErrorLoading(String error);

  /// Empty state message when no teams exist for the tournament
  ///
  /// In en, this message translates to:
  /// **'No teams have been loaded yet.'**
  String get teamListEmpty;

  /// Empty state message when no teams match the search query
  ///
  /// In en, this message translates to:
  /// **'No teams matching \"{query}\"'**
  String teamListNoTeamsMatching(String query);

  /// Subtitle on a team card showing the number of logged notes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notes logged} other{{count} note(s)}}'**
  String teamListNoteCount(int count);

  /// Badge on a team card indicating the count of major/disabled violations
  ///
  /// In en, this message translates to:
  /// **'{count} MAJOR'**
  String teamListMajorCountBadge(int count);

  /// Title of the team incident history bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Team {teamNumber} History'**
  String teamListTeamHistoryTitle(String teamNumber);

  /// Empty state message inside a team's history sheet
  ///
  /// In en, this message translates to:
  /// **'No notes logged for this team yet.'**
  String get teamListNoNotesForTeam;

  /// Heading for a note that is not tied to a specific match
  ///
  /// In en, this message translates to:
  /// **'General Note'**
  String get teamListGeneralNote;

  /// Line listing violated rule codes in team history
  ///
  /// In en, this message translates to:
  /// **'Rules: {rules}'**
  String teamListRulesList(String rules);

  /// Attribution line showing which referee logged a note
  ///
  /// In en, this message translates to:
  /// **'By {refereeName}'**
  String teamListByReferee(String refereeName);

  /// Fallback team name when a team has no custom name
  ///
  /// In en, this message translates to:
  /// **'Team {teamNumber}'**
  String teamFallbackName(String teamNumber);

  /// Snackbar message when syncing notes from the Incident Logger screen
  ///
  /// In en, this message translates to:
  /// **'Syncing with referee network...'**
  String get incidentsSyncingNetwork;

  /// Search input hint on the Incident Logger screen
  ///
  /// In en, this message translates to:
  /// **'Search by team number, rule, or notes...'**
  String get incidentsSearchHint;

  /// Error message when incident notes fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading notes: {error}'**
  String incidentsErrorLoading(String error);

  /// Empty state message when no incident notes have been logged
  ///
  /// In en, this message translates to:
  /// **'No notes logged yet for this tournament.'**
  String get incidentsEmptyTournament;

  /// Empty state message when no incident notes match the search query
  ///
  /// In en, this message translates to:
  /// **'No matching notes found.'**
  String get incidentsNoMatchingNotes;

  /// Footer on an incident note card showing author and timestamp
  ///
  /// In en, this message translates to:
  /// **'Logged by {refereeName} at {time}'**
  String incidentsLoggedByAt(String refereeName, String time);

  /// Tooltip for the delete note icon button
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get incidentsDeleteNoteTooltip;

  /// Title of the delete note confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Note?'**
  String get incidentsDeleteNoteTitle;

  /// Body of the delete note confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this note?'**
  String get incidentsDeleteNoteConfirm;

  /// Title of the Add Incident bottom sheet
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get incidentsNewNoteTitle;

  /// Input label for the required team number field
  ///
  /// In en, this message translates to:
  /// **'Team Number *'**
  String get incidentsTeamNumberLabel;

  /// Input hint for the team number field
  ///
  /// In en, this message translates to:
  /// **'e.g. 1234A'**
  String get incidentsTeamNumberHint;

  /// Input label for the optional match field
  ///
  /// In en, this message translates to:
  /// **'Match (Optional)'**
  String get incidentsMatchOptionalLabel;

  /// Input hint for the match field
  ///
  /// In en, this message translates to:
  /// **'e.g. Q42'**
  String get incidentsMatchOptionalHint;

  /// Label before the quick-select team chips for the chosen match
  ///
  /// In en, this message translates to:
  /// **'Teams in match:'**
  String get incidentsTeamsInMatch;

  /// Section label for selecting the incident severity/type
  ///
  /// In en, this message translates to:
  /// **'Note Type'**
  String get incidentsNoteTypeLabel;

  /// Section label for selecting violated rules
  ///
  /// In en, this message translates to:
  /// **'Rule Violations'**
  String get incidentsRuleViolationsLabel;

  /// Button label to open the full rule selection sheet
  ///
  /// In en, this message translates to:
  /// **'Show More Rules'**
  String get incidentsShowMoreRules;

  /// Input label for free-text referee notes
  ///
  /// In en, this message translates to:
  /// **'Referee Notes'**
  String get incidentsRefereeNotesLabel;

  /// Input hint for free-text referee notes
  ///
  /// In en, this message translates to:
  /// **'Describe details, warnings given, or match conditions...'**
  String get incidentsRefereeNotesHint;

  /// Snackbar message when attempting to save a note without a team number
  ///
  /// In en, this message translates to:
  /// **'Please enter a team number'**
  String get incidentsEnterTeamValidation;

  /// Short label for General severity
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get severityGeneral;

  /// Short label for Minor violation severity
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severityMinor;

  /// Short label for Major violation severity
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get severityMajor;

  /// Short label for Inspection note type
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get severityInspection;

  /// Short label for Disabled robot note type
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get severityDisabled;

  /// Uppercase badge label for Disabled severity
  ///
  /// In en, this message translates to:
  /// **'DISABLED'**
  String get severityBadgeDisabled;

  /// Uppercase badge label for Major violation severity
  ///
  /// In en, this message translates to:
  /// **'MAJOR VIOLATION'**
  String get severityBadgeMajor;

  /// Uppercase badge label for Inspection severity
  ///
  /// In en, this message translates to:
  /// **'INSPECTION'**
  String get severityBadgeInspection;

  /// Uppercase badge label for Minor violation severity
  ///
  /// In en, this message translates to:
  /// **'MINOR'**
  String get severityBadgeMinor;

  /// Uppercase badge label for General severity
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get severityBadgeGeneral;

  /// Header title of the rule selection modal sheet
  ///
  /// In en, this message translates to:
  /// **'Select Rule Violations'**
  String get ruleSelectionTitle;

  /// Subtitle showing program, game title, and rule count in the rule picker
  ///
  /// In en, this message translates to:
  /// **'{program} {gameTitle} ({count, plural, =1{1 rule} other{{count} rules}})'**
  String ruleSelectionSubtitle(String program, String gameTitle, int count);

  /// Search input hint in the rule selection modal sheet
  ///
  /// In en, this message translates to:
  /// **'Search by rule code (SG1, GG2...) or summary...'**
  String get ruleSelectionSearchHint;

  /// Empty state heading in the rule selection modal sheet
  ///
  /// In en, this message translates to:
  /// **'No matching rules found'**
  String get ruleSelectionNoMatchingRules;

  /// Empty state subtitle in the rule selection modal sheet
  ///
  /// In en, this message translates to:
  /// **'Try searching for another rule code or keyword.'**
  String get ruleSelectionNoMatchingRulesSubtitle;

  /// Button in rule details sheet to open the official manual
  ///
  /// In en, this message translates to:
  /// **'View in Manual'**
  String get rulesViewInManual;

  /// Button in rule details sheet to search the official Q&A for the rule
  ///
  /// In en, this message translates to:
  /// **'Search Q&A'**
  String get rulesSearchQa;

  /// Button on the Rules screen to open the program's Game Manual
  ///
  /// In en, this message translates to:
  /// **'{program} Manual'**
  String rulesProgramManual(String program);

  /// Button on the Rules screen to open the official Q&A system
  ///
  /// In en, this message translates to:
  /// **'Official Q&A'**
  String get rulesOfficialQa;

  /// Search input hint on the Game Rules Summary screen
  ///
  /// In en, this message translates to:
  /// **'Search rules (e.g. G12, SG6, Pinning, Autonomous)'**
  String get rulesSearchHint;

  /// Empty state heading on the Game Rules Summary screen
  ///
  /// In en, this message translates to:
  /// **'No matching rules found.'**
  String get rulesNoMatchingRules;

  /// Empty state subtitle on the Game Rules Summary screen
  ///
  /// In en, this message translates to:
  /// **'Try searching with a different rule code or keyword.'**
  String get rulesNoMatchingRulesSubtitle;

  /// Disclaimer banner text at the bottom of the Game Rules Summary screen
  ///
  /// In en, this message translates to:
  /// **'DISCLAIMER:  These are a summary of the official rules and are only for reference - check the game manual before you make a ruling.'**
  String get rulesDisclaimerBanner;

  /// Tooltip for dismissing the rules disclaimer banner
  ///
  /// In en, this message translates to:
  /// **'Dismiss disclaimer'**
  String get rulesDismissDisclaimerTooltip;

  /// Rule category name for Specific Game Rules
  ///
  /// In en, this message translates to:
  /// **'Specific Game Rules'**
  String get ruleGroupSpecificGame;

  /// Rule category name for Scoring Rules
  ///
  /// In en, this message translates to:
  /// **'Scoring Rules'**
  String get ruleGroupScoring;

  /// Rule category name for General Game Rules
  ///
  /// In en, this message translates to:
  /// **'General Game Rules'**
  String get ruleGroupGeneralGame;

  /// Rule category name for General Rules
  ///
  /// In en, this message translates to:
  /// **'General Rules'**
  String get ruleGroupGeneral;

  /// Rule category name for Safety Rules
  ///
  /// In en, this message translates to:
  /// **'Safety Rules'**
  String get ruleGroupSafety;

  /// Rule category name for Robot Rules
  ///
  /// In en, this message translates to:
  /// **'Robot Rules'**
  String get ruleGroupRobot;

  /// Rule category name for Robot Skills Challenge Rules
  ///
  /// In en, this message translates to:
  /// **'Robot Skills Challenge Rules'**
  String get ruleGroupRobotSkills;

  /// Rule category name for Tournament Rules
  ///
  /// In en, this message translates to:
  /// **'Tournament Rules'**
  String get ruleGroupTournament;

  /// Rule category name for VEX U Game Rules
  ///
  /// In en, this message translates to:
  /// **'VEX U Game Rules'**
  String get ruleGroupVexUGame;

  /// Rule category name for VEX U Robot Rules
  ///
  /// In en, this message translates to:
  /// **'VEX U Robot Rules'**
  String get ruleGroupVexURobot;

  /// Rule category name for VEX U Robot Skills Challenge Rules
  ///
  /// In en, this message translates to:
  /// **'VEX U Robot Skills Challenge Rules'**
  String get ruleGroupVexUSkills;

  /// Rule category name for VEX U Tournament Rules
  ///
  /// In en, this message translates to:
  /// **'VEX U Tournament Rules'**
  String get ruleGroupVexUTournament;

  /// AppBar title on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header for theme and language settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// Helper description under Appearance for theme mode selection
  ///
  /// In en, this message translates to:
  /// **'Select theme mode. Device mode automatically follows your operating system light or dark setting.'**
  String get settingsThemeDescription;

  /// Theme mode segment label for following device theme
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsThemeDevice;

  /// Theme mode segment label for light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme mode segment label for dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Dropdown label for selecting the application language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// Dropdown option to follow the device's operating system language
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsLanguageSystemDefault;

  /// Section header for referee profile configuration
  ///
  /// In en, this message translates to:
  /// **'Referee Setup'**
  String get settingsRefereeSetupSection;

  /// Input label for the referee display name
  ///
  /// In en, this message translates to:
  /// **'Referee Display Name'**
  String get settingsRefereeNameLabel;

  /// Input hint for the referee display name
  ///
  /// In en, this message translates to:
  /// **'e.g. Field 1 Head Referee'**
  String get settingsRefereeNameHint;

  /// Section header for sync and sharing when not yet shared
  ///
  /// In en, this message translates to:
  /// **'Sync & Sharing'**
  String get settingsSyncSharingSection;

  /// Card title when event sharing is not enabled
  ///
  /// In en, this message translates to:
  /// **'Sharing Not Enabled'**
  String get settingsSharingNotEnabled;

  /// Description explaining local storage when sharing is not enabled
  ///
  /// In en, this message translates to:
  /// **'Notes are stored locally on this device. Once sharing is enabled for this event, the share admin can configure and manage the sync server.'**
  String get settingsSharingNotEnabledDescription;

  /// Section header for sync server configuration
  ///
  /// In en, this message translates to:
  /// **'Sync Server Configuration'**
  String get settingsSyncServerConfigSection;

  /// Subtitle for sync server configuration when user is share admin
  ///
  /// In en, this message translates to:
  /// **'Connect to the cloud server or a server on your local network'**
  String get settingsSyncServerConfigAdminDesc;

  /// Subtitle for sync server configuration when user is a member
  ///
  /// In en, this message translates to:
  /// **'Sync server is configured by the share admin for this event'**
  String get settingsSyncServerConfigMemberDesc;

  /// Notice shown to non-admin participants about server configuration
  ///
  /// In en, this message translates to:
  /// **'Managed by Host ({adminName}). Only the share admin can configure the sync server for this event.'**
  String settingsManagedByHostNotice(String adminName);

  /// Dropdown label for selecting the sync server mode
  ///
  /// In en, this message translates to:
  /// **'Sync Server Mode'**
  String get settingsSyncServerModeLabel;

  /// Dropdown item for the cloud sync server
  ///
  /// In en, this message translates to:
  /// **'Cloud Server ({cloudUrl})'**
  String settingsServerOptionCloud(String cloudUrl);

  /// Dropdown item for the venue LAN sync server
  ///
  /// In en, this message translates to:
  /// **'Local Server (http://roboref.local:8080)'**
  String get settingsServerOptionLan;

  /// Dropdown item and input label for a custom sync server URL
  ///
  /// In en, this message translates to:
  /// **'Custom Server URL'**
  String get settingsServerOptionCustom;

  /// Hint text for the custom server URL input
  ///
  /// In en, this message translates to:
  /// **'e.g. http://localhost:8080 or https://sync.roboref.app'**
  String get settingsCustomServerUrlHint;

  /// Label for the server connection status row
  ///
  /// In en, this message translates to:
  /// **'Server Status:'**
  String get settingsServerStatusLabel;

  /// Label for the note synchronization status row
  ///
  /// In en, this message translates to:
  /// **'Sync Status:'**
  String get settingsSyncStatusLabel;

  /// Status text shown while synchronization is active
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get settingsSyncingStatus;

  /// Status text shown when sync is idle and ready
  ///
  /// In en, this message translates to:
  /// **'Idle / Ready'**
  String get settingsIdleReadyStatus;

  /// Label displaying the unique device identifier
  ///
  /// In en, this message translates to:
  /// **'Device UUID: {deviceId}'**
  String settingsDeviceUuid(String deviceId);

  /// Label displaying the last synchronization timestamp
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String settingsLastSync(String time);

  /// Label displaying the last synchronization error
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String settingsErrorPrefix(String error);

  /// Snackbar message when Sync Now is pressed
  ///
  /// In en, this message translates to:
  /// **'Triggered background sync...'**
  String get settingsTriggeredSyncSnackbar;

  /// Button label to trigger synchronization immediately
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsSyncNowButton;

  /// Snackbar message while testing connection to a server URL
  ///
  /// In en, this message translates to:
  /// **'Testing connection to {target}...'**
  String settingsTestingConnectionTo(String target);

  /// Fallback target name when testing an empty server URL
  ///
  /// In en, this message translates to:
  /// **'server'**
  String get settingsTestingDefaultTarget;

  /// Snackbar message when connection test succeeds
  ///
  /// In en, this message translates to:
  /// **'Connection successful: {message}'**
  String settingsConnectionSuccessful(String message);

  /// Snackbar message when connection test fails
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {message}'**
  String settingsConnectionFailed(String message);

  /// Button label while server connection test is running
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get settingsTestingButton;

  /// Button label to test server connectivity
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settingsTestConnectionButton;

  /// Connection badge text when connected to localhost
  ///
  /// In en, this message translates to:
  /// **'Local Server (localhost)'**
  String get settingsBadgeLocalhost;

  /// Connection badge text when connected to a local LAN server
  ///
  /// In en, this message translates to:
  /// **'Venue LAN (roboref.local)'**
  String get settingsBadgeVenueLan;

  /// Connection badge text when connected to the cloud server
  ///
  /// In en, this message translates to:
  /// **'Cloud Server'**
  String get settingsBadgeCloudServer;

  /// Connection badge text when the server is unreachable
  ///
  /// In en, this message translates to:
  /// **'Offline / Unreachable'**
  String get settingsBadgeOffline;

  /// Connection badge text while checking server status
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get settingsBadgeChecking;

  /// Section header for event links on the manage tab
  ///
  /// In en, this message translates to:
  /// **'Event Information'**
  String get settingsEventInfoSection;

  /// List tile title linking to the event's page on VEX Events
  ///
  /// In en, this message translates to:
  /// **'VEX Events Page'**
  String get settingsVexEventsPage;

  /// Section header for About RoboRef
  ///
  /// In en, this message translates to:
  /// **'About RoboRef'**
  String get settingsAboutSection;

  /// List tile title linking to the GitHub source repository
  ///
  /// In en, this message translates to:
  /// **'View Source'**
  String get settingsViewSourceItem;

  /// List tile title and screen title for the Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicyItem;

  /// Snackbar message when the app version string is copied
  ///
  /// In en, this message translates to:
  /// **'Version copied to clipboard'**
  String get settingsVersionCopied;

  /// Title on the version card in Settings
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get settingsCurrentVersionTitle;

  /// Helper text on the version card in Settings
  ///
  /// In en, this message translates to:
  /// **'Use this to let a developer know what version you are using if you encounter an issue.'**
  String get settingsCurrentVersionDescription;

  /// Section header for experimental features
  ///
  /// In en, this message translates to:
  /// **'Experimental Features'**
  String get settingsExperimentalSection;

  /// Checkbox title for enabling experimental features
  ///
  /// In en, this message translates to:
  /// **'Enable extra features that may not work as intended'**
  String get settingsExperimentalCheckboxLabel;

  /// Title of the confirmation dialog when enabling experimental features
  ///
  /// In en, this message translates to:
  /// **'Warning!  Experimental Features!'**
  String get settingsExperimentalWarningTitle;

  /// Content of the confirmation dialog when enabling experimental features
  ///
  /// In en, this message translates to:
  /// **'Ticking this will enable extra features that may not work as intended'**
  String get settingsExperimentalWarningContent;

  /// Section header for importing event CSV data
  ///
  /// In en, this message translates to:
  /// **'Import Event Data'**
  String get settingsImportEventDataSection;

  /// Warning subtitle under Import Event Data
  ///
  /// In en, this message translates to:
  /// **'This feature is experimental and may not work as intended'**
  String get settingsImportEventDataDescription;

  /// Button label to open the Tournament Manager CSV import sheet
  ///
  /// In en, this message translates to:
  /// **'Import Event Data (TM CSV)'**
  String get settingsImportEventDataButton;

  /// AppBar title on the Privacy Policy screen
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// Tooltip for opening the privacy policy in an external browser
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get privacyOpenInBrowserTooltip;

  /// Error heading when privacy policy markdown fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load privacy policy'**
  String get privacyUnableToLoad;

  /// Footer button to view the privacy policy on the web
  ///
  /// In en, this message translates to:
  /// **'View on roboref.app/privacy'**
  String get privacyViewOnWebButton;

  /// Snackbar message when launching the web privacy policy fails
  ///
  /// In en, this message translates to:
  /// **'Could not open https://roboref.app/privacy in browser.'**
  String get privacyCouldNotOpenBrowser;

  /// Snackbar message when launching the web privacy policy throws an error
  ///
  /// In en, this message translates to:
  /// **'Could not open web link.'**
  String get privacyCouldNotOpenLink;

  /// Header title of the Event Share modal bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Event Sharing & Sync'**
  String get eventShareTitle;

  /// Badge shown when event notes are stored strictly locally
  ///
  /// In en, this message translates to:
  /// **'LOCAL ONLY'**
  String get eventShareBadgeLocalOnly;

  /// Heading in the local-only view of the Event Share sheet
  ///
  /// In en, this message translates to:
  /// **'Notes are stored entirely locally on this device.'**
  String get eventShareLocalOnlyTitle;

  /// Description in the local-only view of the Event Share sheet
  ///
  /// In en, this message translates to:
  /// **'To collaborate with alliance referees and scorekeepers, share this event online to synchronize notes in real time.'**
  String get eventShareLocalOnlyDescription;

  /// Button label while checking for existing share sessions
  ///
  /// In en, this message translates to:
  /// **'Checking Server...'**
  String get eventShareCheckingServerButton;

  /// Divider label between creating a share and joining via code
  ///
  /// In en, this message translates to:
  /// **'OR JOIN AN EXISTING SHARE'**
  String get eventShareOrJoinExisting;

  /// Input label for entering a 6-digit share code
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit Share Code'**
  String get eventShareEnterCodeLabel;

  /// Input hint for entering a 6-digit share code
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC123'**
  String get eventShareEnterCodeHint;

  /// Snackbar message after joining a share session by code
  ///
  /// In en, this message translates to:
  /// **'Joined shared session successfully!'**
  String get eventShareJoinedSuccessSnackbar;

  /// Button label to join a share session
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get eventShareJoinButton;

  /// Heading on the conflict warning card when a share session already exists
  ///
  /// In en, this message translates to:
  /// **'Existing Share Session Found'**
  String get eventShareConflictTitle;

  /// Explanation of an existing active share session for the event SKU
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A shared session for {sku} is already active on the network, hosted by {adminName} with 1 participant.} other{A shared session for {sku} is already active on the network, hosted by {adminName} with {count} participants.}}'**
  String eventShareConflictDescription(String sku, String adminName, int count);

  /// Snackbar message when joining the existing host's session from the conflict card
  ///
  /// In en, this message translates to:
  /// **'Joined {adminName}\'s session'**
  String eventShareJoinedAdminSessionSnackbar(String adminName);

  /// Button label to join the existing host's session
  ///
  /// In en, this message translates to:
  /// **'Join {adminName}'**
  String eventShareJoinAdminButton(String adminName);

  /// Button label to force-create a separate share session despite an existing one
  ///
  /// In en, this message translates to:
  /// **'Create Separate Share Anyway'**
  String get eventShareCreateSeparateAnywayButton;

  /// Status heading when sharing online as the session host/admin
  ///
  /// In en, this message translates to:
  /// **'Sharing: {serverType} (Host / Admin)'**
  String eventShareSharingStatusAdmin(String serverType);

  /// Status heading when connected to a shared session as a member
  ///
  /// In en, this message translates to:
  /// **'Sharing: {serverType} (Member)'**
  String eventShareSharingStatusMember(String serverType);

  /// Subtitle explaining admin capabilities in a shared session
  ///
  /// In en, this message translates to:
  /// **'You are the admin on {serverType}. You can invite referees and manage participants.'**
  String eventShareAdminRoleDescription(String serverType);

  /// Subtitle explaining member status in a shared session
  ///
  /// In en, this message translates to:
  /// **'Hosted by {adminName} on {serverType}. Notes synchronize automatically.'**
  String eventShareMemberRoleDescription(String adminName, String serverType);

  /// Heading above the QR code in the Event Share sheet
  ///
  /// In en, this message translates to:
  /// **'Scan to Join Share Session'**
  String get eventShareScanToJoinTitle;

  /// Prefix label before the 6-character share code
  ///
  /// In en, this message translates to:
  /// **'Share Code: '**
  String get eventShareCodeLabel;

  /// Tooltip for copying the 6-character share code
  ///
  /// In en, this message translates to:
  /// **'Copy Share Code'**
  String get eventShareCopyCodeTooltip;

  /// Snackbar message when the share code is copied
  ///
  /// In en, this message translates to:
  /// **'Share code copied to clipboard!'**
  String get eventShareCodeCopiedSnackbar;

  /// Snackbar message when the join URL is copied
  ///
  /// In en, this message translates to:
  /// **'Join link copied to clipboard!'**
  String get eventShareJoinLinkCopiedSnackbar;

  /// Button label to copy the share join URL
  ///
  /// In en, this message translates to:
  /// **'Copy Join Link'**
  String get eventShareCopyJoinLinkButton;

  /// Section header showing the count of connected referees
  ///
  /// In en, this message translates to:
  /// **'Connected Referees ({count})'**
  String eventShareConnectedRefereesTitle(int count);

  /// Tooltip for viewing the referee name history dialog
  ///
  /// In en, this message translates to:
  /// **'Referee name history'**
  String get eventShareNameHistoryTooltip;

  /// Tooltip for refreshing the connected participants list
  ///
  /// In en, this message translates to:
  /// **'Refresh participant list'**
  String get eventShareRefreshParticipantsTooltip;

  /// Badge next to the current user's participant entry
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get eventShareBadgeYou;

  /// Badge next to the admin participant entry
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get eventShareBadgeAdmin;

  /// Tooltip for viewing previous display names of a specific referee
  ///
  /// In en, this message translates to:
  /// **'Previous names for {refereeName}'**
  String eventSharePreviousNamesForTooltip(String refereeName);

  /// Tooltip for removing a participant from the shared session
  ///
  /// In en, this message translates to:
  /// **'Remove {refereeName}'**
  String eventShareRemoveParticipantTooltip(String refereeName);

  /// Button label for the admin to close and delete the share session
  ///
  /// In en, this message translates to:
  /// **'Close & Delete Share Session'**
  String get eventShareCloseAndDeleteButton;

  /// Warning note below the close button when other participants are still connected
  ///
  /// In en, this message translates to:
  /// **'Note: The admin cannot leave until all other referees have left or been removed.'**
  String get eventShareAdminCannotLeaveNote;

  /// Button label for a member to leave the shared event
  ///
  /// In en, this message translates to:
  /// **'Leave Shared Event'**
  String get eventShareLeaveSharedEventButton;

  /// Dialog title when confirming removal of a participant
  ///
  /// In en, this message translates to:
  /// **'Remove {refereeName}?'**
  String eventShareRemoveParticipantTitle(String refereeName);

  /// Dialog body when confirming removal of a participant
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {refereeName} from this shared session? They will stop syncing new notes.'**
  String eventShareRemoveParticipantConfirm(String refereeName);

  /// Dialog title when the admin tries to leave while others are connected
  ///
  /// In en, this message translates to:
  /// **'Cannot Leave Share'**
  String get eventShareCannotLeaveTitle;

  /// Dialog body when the admin tries to leave while others are connected
  ///
  /// In en, this message translates to:
  /// **'You cannot leave or close this session while {count} other referees are connected. Please remove all participants first or wait for them to leave.'**
  String eventShareCannotLeaveContent(int count);

  /// Dialog title when confirming closing and deleting a share session
  ///
  /// In en, this message translates to:
  /// **'Close & Delete Share?'**
  String get eventShareCloseDeleteTitle;

  /// Dialog body when confirming closing and deleting a share session
  ///
  /// In en, this message translates to:
  /// **'Closing the session will delete it from the sync server and purge cloud notes. Your local notes will remain safely on this device.'**
  String get eventShareCloseDeleteContent;

  /// Snackbar message after closing and deleting a share session
  ///
  /// In en, this message translates to:
  /// **'Share session closed and cloud data deleted.'**
  String get eventShareClosedDeletedSnackbar;

  /// Confirmation button label to close and delete a share session
  ///
  /// In en, this message translates to:
  /// **'Close & Delete'**
  String get eventShareCloseDeleteConfirmButton;

  /// Dialog title when a member confirms leaving a shared event
  ///
  /// In en, this message translates to:
  /// **'Leave Shared Event?'**
  String get eventShareLeaveEventTitle;

  /// Dialog body when a member confirms leaving a shared event
  ///
  /// In en, this message translates to:
  /// **'You will disconnect from this share session and stop receiving sync updates. Your local notes will remain on your device.'**
  String get eventShareLeaveEventContent;

  /// Snackbar message after a member leaves a shared event
  ///
  /// In en, this message translates to:
  /// **'Left shared event session.'**
  String get eventShareLeftEventSnackbar;

  /// Confirmation button label to leave a shared event
  ///
  /// In en, this message translates to:
  /// **'Leave Event'**
  String get eventShareLeaveEventConfirmButton;

  /// Dialog title for a single referee's name history
  ///
  /// In en, this message translates to:
  /// **'Name History'**
  String get eventShareNameHistoryDialogTitle;

  /// Label showing a referee's current display name
  ///
  /// In en, this message translates to:
  /// **'Current Name: {refereeName}'**
  String eventShareCurrentNameLabel(String refereeName);

  /// Subheading above the list of previous names for a referee
  ///
  /// In en, this message translates to:
  /// **'Previous names at this event:'**
  String get eventSharePreviousNamesLabel;

  /// Empty state text when a referee has no previous names
  ///
  /// In en, this message translates to:
  /// **'No previous names recorded for this referee at this event.'**
  String get eventShareNoPreviousNamesForReferee;

  /// Dialog title for all connected referees' name histories
  ///
  /// In en, this message translates to:
  /// **'Referee Name History'**
  String get eventShareAllNameHistoryDialogTitle;

  /// Empty state text when no referee has any previous names
  ///
  /// In en, this message translates to:
  /// **'No previous names recorded for any referee at this event.'**
  String get eventShareNoPreviousNamesForAny;

  /// Short italic label when a participant has no previous names
  ///
  /// In en, this message translates to:
  /// **'No previous names'**
  String get eventShareNoPreviousNamesShort;

  /// Error message when attempting a server request with an empty server URL
  ///
  /// In en, this message translates to:
  /// **'Sync server URL is not configured'**
  String get errorSyncServerUrlNotConfigured;

  /// Error message when sync push receives a non-200 HTTP status
  ///
  /// In en, this message translates to:
  /// **'Server responded with status {statusCode}'**
  String errorServerRespondedWithStatus(int statusCode);

  /// Validation error when an operation requires a non-empty tournament SKU
  ///
  /// In en, this message translates to:
  /// **'SKU cannot be empty'**
  String get errorSkuCannotBeEmpty;

  /// Validation error when imported CSV text contains no lines
  ///
  /// In en, this message translates to:
  /// **'CSV is empty'**
  String get errorCsvIsEmpty;

  /// Error message when parsing a Teams CSV fails
  ///
  /// In en, this message translates to:
  /// **'Failed to parse Teams CSV: {error}'**
  String errorFailedToParseTeamsCsv(String error);

  /// Error message when parsing a Matches CSV fails
  ///
  /// In en, this message translates to:
  /// **'Failed to parse Matches CSV: {error}'**
  String errorFailedToParseMatchesCsv(String error);

  /// Error message when the VEX Events proxy returns an HTTP error
  ///
  /// In en, this message translates to:
  /// **'Server returned error {statusCode}: {body}'**
  String errorServerReturnedError(int statusCode, String body);

  /// Error message when all candidate VEX Events proxy URLs fail
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to VEX Events proxy: {error}'**
  String errorFailedToConnectVexEventsProxy(String error);

  /// Error message when searching events throws an unexpected error
  ///
  /// In en, this message translates to:
  /// **'Failed to search events via sync server: {error}'**
  String errorFailedToSearchEventsViaSyncServer(String error);

  /// Error message when fetching tournament info from VEX Events fails
  ///
  /// In en, this message translates to:
  /// **'Could not connect to VEX Events: {error}'**
  String errorCouldNotConnectToVexEvents(String error);

  /// Error message when a tournament SKU does not exist on VEX Events
  ///
  /// In en, this message translates to:
  /// **'Tournament \"{sku}\" not found on VEX Events'**
  String errorTournamentNotFoundOnVexEvents(String sku);

  /// Error message when fetching tournament teams/matches throws an unexpected exception
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch tournament data from sync server: {error}'**
  String errorFailedToFetchTournamentData(String error);

  /// Fallback error message when importing an event fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load tournament data'**
  String get errorFailedToLoadTournamentData;

  /// Message returned when a match or team refresh is already running
  ///
  /// In en, this message translates to:
  /// **'Refresh already in progress'**
  String get errorRefreshAlreadyInProgress;

  /// Internal status message when a provider is disposed before completion
  ///
  /// In en, this message translates to:
  /// **'Provider not mounted'**
  String get errorProviderNotMounted;

  /// Health check error when the configured server URL is blank
  ///
  /// In en, this message translates to:
  /// **'Server URL is empty'**
  String get errorServerUrlIsEmpty;

  /// Health check error when the server URL cannot be parsed as a valid URI
  ///
  /// In en, this message translates to:
  /// **'Invalid server URL format'**
  String get errorInvalidServerUrlFormat;

  /// Server type label for localhost in health check messages
  ///
  /// In en, this message translates to:
  /// **'Local Server'**
  String get statusServerTypeLocal;

  /// Server type label for a venue LAN server in health check messages
  ///
  /// In en, this message translates to:
  /// **'Venue LAN'**
  String get statusServerTypeVenueLan;

  /// Server type label for the cloud server in health check messages
  ///
  /// In en, this message translates to:
  /// **'Cloud Server'**
  String get statusServerTypeCloud;

  /// Health check message when connected to a sync server
  ///
  /// In en, this message translates to:
  /// **'Connected to {serverType} ({latencyMs} ms)'**
  String statusConnectedToServer(String serverType, int latencyMs);

  /// Health check message when server responds with a non-200 HTTP code
  ///
  /// In en, this message translates to:
  /// **'Server reachable but returned HTTP {statusCode}'**
  String errorServerReachableHttpStatus(int statusCode);

  /// Generic health check error when the server cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Could not reach server'**
  String get errorCouldNotReachServer;

  /// Health check error when the request times out
  ///
  /// In en, this message translates to:
  /// **'Connection timed out (server unreachable)'**
  String get errorConnectionTimedOut;

  /// Health check error when socket connection is refused or host lookup fails
  ///
  /// In en, this message translates to:
  /// **'Connection refused / host unreachable'**
  String get errorConnectionRefused;

  /// Health check error when a client network or CORS error occurs
  ///
  /// In en, this message translates to:
  /// **'Network or CORS error connecting to server'**
  String get errorNetworkOrCors;

  /// Error message when creating a share session returns an HTTP error
  ///
  /// In en, this message translates to:
  /// **'Failed to create share session (HTTP {statusCode})'**
  String errorFailedToCreateShareHttp(int statusCode);

  /// Error message when the admin attempts to leave a session with active participants
  ///
  /// In en, this message translates to:
  /// **'The admin cannot leave while other referees are in the session.'**
  String get errorAdminCannotLeaveWithActiveParticipants;

  /// Fallback error message when leaving a share session fails
  ///
  /// In en, this message translates to:
  /// **'Failed to leave share session'**
  String get errorFailedToLeaveShare;

  /// Internal error message when ShareController is disposed
  ///
  /// In en, this message translates to:
  /// **'Controller disposed'**
  String get errorControllerDisposed;

  /// Fallback error message when creating a share fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create share'**
  String get errorFailedToCreateShare;

  /// Error message when joining a share session returns null/failure
  ///
  /// In en, this message translates to:
  /// **'Could not join share session. Check code or connection.'**
  String get errorCouldNotJoinShareSession;

  /// Error message when removing a participant fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove participant'**
  String get errorFailedToRemoveParticipant;

  /// Message shown to a participant who was kicked/removed by the admin
  ///
  /// In en, this message translates to:
  /// **'You were removed from this shared event session.'**
  String get errorRemovedFromSharedSession;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
