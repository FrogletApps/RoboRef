// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RoboRef';

  @override
  String get appTitleLocal => 'RoboRef Local';

  @override
  String get appTitleTest => 'RoboRef Test';

  @override
  String get envBadgeLocal => 'LOCAL';

  @override
  String get envBadgeTest => 'TEST';

  @override
  String get envBadgeRelease => 'RELEASE';

  @override
  String get commonAll => 'All';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonOk => 'OK';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonClearSearch => 'Clear search';

  @override
  String get commonClearAll => 'Clear All';

  @override
  String get commonDone => 'Done';

  @override
  String commonDoneCount(int count) {
    return 'Done ($count)';
  }

  @override
  String get commonAddNote => 'Add Note';

  @override
  String get commonSaveNote => 'Save Note';

  @override
  String get commonShareEventOnline => 'Share Event Online';

  @override
  String get commonHeadReferee => 'Head Referee';

  @override
  String get commonReferee => 'Referee';

  @override
  String get commonCustom => 'Custom';

  @override
  String commonCouldNotOpenLink(String url) {
    return 'Could not open link: $url';
  }

  @override
  String commonLinkCopiedToClipboard(String url) {
    return 'Link copied to clipboard: $url';
  }

  @override
  String get commonServerTypeCloud => 'RoboRef Cloud Server';

  @override
  String get commonServerTypeOther => 'Other Server';

  @override
  String get homeRecentTournaments => 'Recent Tournaments';

  @override
  String homeSharingLabel(String serverType) {
    return 'Sharing: $serverType';
  }

  @override
  String homeRemovedFromRecent(String sku) {
    return 'Removed $sku from recent list';
  }

  @override
  String get homeRemoveFromRecent => 'Remove from recent';

  @override
  String get homeShareRoboRef => 'Share RoboRef';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeAddNewEvent => 'Add a new event';

  @override
  String get homeWelcomeTitle => 'Welcome to RoboRef!';

  @override
  String get homeWelcomeDescription =>
      'This is an anomaly log for Head Referees at VEX robotics competitions.';

  @override
  String get homeWelcomeInstruction =>
      'To get started, tap the \"Add a new event\" button above.';

  @override
  String get shareTitle => 'Share RoboRef';

  @override
  String get shareDescription =>
      'Scan the QR code below or share the link with head referees, alliance referees, and scorekeepers.';

  @override
  String get shareLinkCopied => 'RoboRef link copied to clipboard!';

  @override
  String get shareCopyLink => 'Copy Link';

  @override
  String get changelogTitle => 'Change Log';

  @override
  String get changelogReloadTooltip => 'Reload Changelog';

  @override
  String get changelogLoading => 'Loading changelog...';

  @override
  String get changelogUnableToLoad => 'Unable to load change log';

  @override
  String get changelogReleaseHistory => 'Release History';

  @override
  String get changelogReleaseNotesFallback => 'Release Notes';

  @override
  String get changelogSearchHint => 'Search release notes...';

  @override
  String changelogNoEntriesMatching(String query) {
    return 'No changelog entries found matching \"$query\"';
  }

  @override
  String changelogLinkCopied(String href) {
    return 'Link copied: $href';
  }

  @override
  String get eventSelectionTitle => 'Pick An Event';

  @override
  String get eventSelectionReloadTooltip => 'Reload Events';

  @override
  String get eventSelectionSearchHint =>
      'Search by SKU (RE-... / VE-...) or event name';

  @override
  String get eventSelectionAllRegions => 'All Regions';

  @override
  String eventSelectionRegionSelected(String region) {
    return 'Region: $region';
  }

  @override
  String eventSelectionRegionsSelected(int count) {
    return 'Regions: $count selected';
  }

  @override
  String get eventSelectionAllStates => 'All States';

  @override
  String get eventSelectionAllProvinces => 'All Provinces';

  @override
  String eventSelectionStateSelected(String division) {
    return 'State: $division';
  }

  @override
  String eventSelectionProvinceSelected(String division) {
    return 'Province: $division';
  }

  @override
  String eventSelectionAllDivisions(String pluralLabel) {
    return 'All $pluralLabel';
  }

  @override
  String eventSelectionDivisionSelected(String singularLabel, String division) {
    return '$singularLabel: $division';
  }

  @override
  String eventSelectionStatesSelected(int count) {
    return 'States: $count selected';
  }

  @override
  String eventSelectionProvincesSelected(int count) {
    return 'Provinces: $count selected';
  }

  @override
  String eventSelectionDivisionsSelected(String pluralLabel, int count) {
    return '$pluralLabel: $count selected';
  }

  @override
  String get eventSelectionResetFilters => 'Reset Filters';

  @override
  String get eventSelectionEnableMultiselect => 'Enable Multiselect';

  @override
  String eventSelectionAddCustomSchedule(String program) {
    return 'Add & fetch custom $program tournament schedule';
  }

  @override
  String eventSelectionCustomTournamentName(String program, String sku) {
    return '$program Tournament ($sku)';
  }

  @override
  String get eventSelectionAddAndSelect => 'Add & Select';

  @override
  String get eventSelectionEventsHeader => 'Events';

  @override
  String eventSelectionFoundEventsSummary(
      int count, String startDate, String endDate) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count events between $startDate and $endDate',
      one: 'Found 1 event between $startDate and $endDate',
    );
    return '$_temp0';
  }

  @override
  String get eventSelectionLoadingEvents =>
      'Loading live events from VEX Events...';

  @override
  String get eventSelectionProxyError =>
      'Could not connect to VEX Events proxy.';

  @override
  String get eventSelectionNoEventsFound =>
      'No events found in this date window.';

  @override
  String get eventSelectionNoEventsSubtitle =>
      'Try loading a wider date range or entering a SKU directly.';

  @override
  String get eventSelectionSearchNext30Days => 'Search Next 30 Days';

  @override
  String get eventSelectionLoadingMoreEvents => 'Loading More Events...';

  @override
  String get eventSelectionLoadMoreEvents => 'Load More Events';

  @override
  String get eventSelectionShowingCachedEvents =>
      'Could not reach server. Showing cached events.';

  @override
  String eventSelectionLoadingTournamentData(String sku) {
    return 'Loading teams and match schedule for $sku...';
  }

  @override
  String eventSelectionLoadedTournamentSummary(
      String eventName, int teamsCount, int matchesCount) {
    String _temp0 = intl.Intl.pluralLogic(
      teamsCount,
      locale: localeName,
      other: '$teamsCount teams',
      one: '1 team',
    );
    String _temp1 = intl.Intl.pluralLogic(
      matchesCount,
      locale: localeName,
      other: '$matchesCount matches',
      one: '1 match',
    );
    return 'Loaded \"$eventName\" ($_temp0, $_temp1)';
  }

  @override
  String eventSelectionLoadNotePrefix(String errorMessage) {
    return 'Note: $errorMessage';
  }

  @override
  String get eventSelectionFilterByRegion => 'Filter by Region';

  @override
  String get eventSelectionSearchRegionHint =>
      'Search region (e.g. United States, UK, Australia)...';

  @override
  String eventSelectionNoRegionsMatching(String query) {
    return 'No regions matching \"$query\"';
  }

  @override
  String eventSelectionRegionIncludes(String divisions) {
    return 'Includes: $divisions';
  }

  @override
  String get eventSelectionFilterByState => 'Filter by State';

  @override
  String get eventSelectionFilterByProvince => 'Filter by Province';

  @override
  String eventSelectionFilterByDivision(String singularLabel) {
    return 'Filter by $singularLabel';
  }

  @override
  String get eventSelectionSearchStatesHint =>
      'Search states (e.g. Texas, TX)...';

  @override
  String get eventSelectionSearchProvincesHint =>
      'Search provinces (e.g. Texas, TX)...';

  @override
  String eventSelectionSearchDivisionsHint(String pluralLabelLower) {
    return 'Search $pluralLabelLower (e.g. Texas, TX)...';
  }

  @override
  String eventSelectionNoStatesMatching(String query) {
    return 'No states matching \"$query\"';
  }

  @override
  String eventSelectionNoProvincesMatching(String query) {
    return 'No provinces matching \"$query\"';
  }

  @override
  String eventSelectionNoDivisionsMatching(
      String pluralLabelLower, String query) {
    return 'No $pluralLabelLower matching \"$query\"';
  }

  @override
  String get workspaceTitleMatchSchedule => 'Match Schedule';

  @override
  String get workspaceTitleTeamHistories => 'Team Histories';

  @override
  String get workspaceTitleNotes => 'RoboRef';

  @override
  String get workspaceTitleRules => 'Game Rules Summary';

  @override
  String get workspaceTitleManage => 'Manage & Sync';

  @override
  String get workspaceNavMatches => 'Matches';

  @override
  String get workspaceNavTeams => 'Teams';

  @override
  String get workspaceNavNotes => 'Notes';

  @override
  String get workspaceNavRules => 'Rules';

  @override
  String get workspaceNavManage => 'Manage';

  @override
  String get workspaceRefreshMatchesTooltip => 'Refresh Matches';

  @override
  String get workspaceImportScheduleTooltip => 'Load / Import Schedule';

  @override
  String get workspaceRefreshTeamsTooltip => 'Refresh Teams';

  @override
  String get workspaceImportTeamsTooltip => 'Load / Import Teams';

  @override
  String get workspaceSyncNotesTooltip => 'Sync Notes';

  @override
  String workspaceHostingOnlineTooltip(int count) {
    return 'Hosting Online ($count connected)';
  }

  @override
  String workspaceConnectedOnlineTooltip(int count) {
    return 'Connected Online ($count connected)';
  }

  @override
  String workspaceLoadedMatchesForSku(int count, String sku) {
    return 'Loaded $count match(es) for $sku';
  }

  @override
  String get workspaceCheckingMatchUpdates =>
      'Checking for match schedule updates...';

  @override
  String workspaceUpdatedMatches(int count) {
    return 'Updated $count match(es)';
  }

  @override
  String get workspaceMatchScheduleUpToDate => 'Match schedule is up to date';

  @override
  String get workspaceFailedToUpdateMatches => 'Failed to update matches';

  @override
  String get workspaceCheckingTeamUpdates =>
      'Checking for team roster updates...';

  @override
  String workspaceUpdatedTeams(int count) {
    return 'Updated $count team(s)';
  }

  @override
  String get workspaceTeamListUpToDate => 'Team list is up to date';

  @override
  String get workspaceFailedToUpdateTeams => 'Failed to update teams';

  @override
  String get workspaceSyncingNotes => 'Syncing notes...';

  @override
  String get eventImportTitle => 'Load Tournament Data';

  @override
  String get eventImportSubtitle =>
      'Paste Tournament Manager (TM) export data below.';

  @override
  String get eventImportTeamsCsvTab => 'Teams CSV';

  @override
  String get eventImportMatchesCsvTab => 'Match Schedule CSV';

  @override
  String get eventImportPasteTeamsLabel => 'Paste Teams CSV Text';

  @override
  String get eventImportPasteMatchesLabel => 'Paste Matches CSV Text';

  @override
  String get eventImportPasteTeamsHint =>
      'Number, Name, City, State, Country\n1234A, RoboKnights, Austin, TX, USA';

  @override
  String get eventImportPasteMatchesHint =>
      'Match, Field, Time, Red 1, Red 2, Blue 1, Blue 2\nQ1, Field 1, 09:00, 1234A, 5678B, 9012C, 3456D';

  @override
  String get eventImportImportingButton => 'Importing...';

  @override
  String get eventImportTeamsButton => 'Import Teams CSV';

  @override
  String get eventImportMatchesButton => 'Import Matches CSV';

  @override
  String get eventImportNoSkuError => 'No tournament SKU selected.';

  @override
  String get eventImportEmptyCsvError => 'Please paste CSV content to import.';

  @override
  String eventImportTeamsSuccess(int count) {
    return 'Successfully imported $count teams!';
  }

  @override
  String eventImportMatchesSuccess(int count) {
    return 'Successfully imported $count matches!';
  }

  @override
  String get matchScheduleSearchHint => 'Search by match (e.g. Q12) or team...';

  @override
  String matchScheduleErrorLoading(String error) {
    return 'Error loading matches: $error';
  }

  @override
  String get matchScheduleEmpty => 'No match schedule has been loaded yet.';

  @override
  String matchScheduleNoMatchesMatching(String query) {
    return 'No matches found matching \"$query\"';
  }

  @override
  String get matchScheduleCheckingButton => 'Checking...';

  @override
  String get matchScheduleCheckButton => 'Check for Schedule';

  @override
  String get matchScheduleFetchOrImportButton => 'Fetch or Import Schedule';

  @override
  String get matchScheduleAllianceTeams => 'TEAMS';

  @override
  String get matchScheduleAllianceRed => 'RED';

  @override
  String get matchScheduleAllianceBlue => 'BLUE';

  @override
  String get matchScheduleNoTeamsAssigned => 'No teams assigned to this match.';

  @override
  String get matchScheduleNoNotesLogged => 'No notes logged';

  @override
  String matchNamePractice(int num) {
    return 'Practice $num';
  }

  @override
  String matchNameQualification(int num) {
    return 'Qualification $num';
  }

  @override
  String matchNameFinalsInstance(int instance, int num) {
    return 'Finals $instance-$num';
  }

  @override
  String matchNameFinals(int num) {
    return 'Finals $num';
  }

  @override
  String get teamListSearchHint => 'Search teams...';

  @override
  String teamListErrorLoading(String error) {
    return 'Error loading teams: $error';
  }

  @override
  String get teamListEmpty => 'No teams have been loaded yet.';

  @override
  String teamListNoTeamsMatching(String query) {
    return 'No teams matching \"$query\"';
  }

  @override
  String teamListNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note(s)',
      zero: 'No notes logged',
    );
    return '$_temp0';
  }

  @override
  String teamListMajorCountBadge(int count) {
    return '$count MAJOR';
  }

  @override
  String teamListTeamHistoryTitle(String teamNumber) {
    return 'Team $teamNumber History';
  }

  @override
  String get teamListNoNotesForTeam => 'No notes logged for this team yet.';

  @override
  String get teamListGeneralNote => 'General Note';

  @override
  String teamListRulesList(String rules) {
    return 'Rules: $rules';
  }

  @override
  String teamListByReferee(String refereeName) {
    return 'By $refereeName';
  }

  @override
  String teamFallbackName(String teamNumber) {
    return 'Team $teamNumber';
  }

  @override
  String get incidentsSyncingNetwork => 'Syncing with referee network...';

  @override
  String get incidentsSearchHint => 'Search by team number, rule, or notes...';

  @override
  String incidentsErrorLoading(String error) {
    return 'Error loading notes: $error';
  }

  @override
  String get incidentsEmptyTournament =>
      'No notes logged yet for this tournament.';

  @override
  String get incidentsNoMatchingNotes => 'No matching notes found.';

  @override
  String incidentsLoggedByAt(String refereeName, String time) {
    return 'Logged by $refereeName at $time';
  }

  @override
  String get incidentsDeleteNoteTooltip => 'Delete Note';

  @override
  String get incidentsDeleteNoteTitle => 'Delete Note?';

  @override
  String get incidentsDeleteNoteConfirm =>
      'Are you sure you want to remove this note?';

  @override
  String get incidentsNewNoteTitle => 'New Note';

  @override
  String get incidentsTeamNumberLabel => 'Team Number *';

  @override
  String get incidentsTeamNumberHint => 'e.g. 1234A';

  @override
  String get incidentsMatchOptionalLabel => 'Match (Optional)';

  @override
  String get incidentsMatchOptionalHint => 'e.g. Q42';

  @override
  String get incidentsTeamsInMatch => 'Teams in match:';

  @override
  String get incidentsNoteTypeLabel => 'Note Type';

  @override
  String get incidentsRuleViolationsLabel => 'Rule Violations';

  @override
  String get incidentsShowMoreRules => 'Show More Rules';

  @override
  String get incidentsRefereeNotesLabel => 'Referee Notes';

  @override
  String get incidentsRefereeNotesHint =>
      'Describe details, warnings given, or match conditions...';

  @override
  String get incidentsEnterTeamValidation => 'Please enter a team number';

  @override
  String get severityGeneral => 'General';

  @override
  String get severityMinor => 'Minor';

  @override
  String get severityMajor => 'Major';

  @override
  String get severityInspection => 'Inspection';

  @override
  String get severityDisabled => 'Disabled';

  @override
  String get severityBadgeDisabled => 'DISABLED';

  @override
  String get severityBadgeMajor => 'MAJOR VIOLATION';

  @override
  String get severityBadgeInspection => 'INSPECTION';

  @override
  String get severityBadgeMinor => 'MINOR';

  @override
  String get severityBadgeGeneral => 'GENERAL';

  @override
  String get ruleSelectionTitle => 'Select Rule Violations';

  @override
  String ruleSelectionSubtitle(String program, String gameTitle, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules',
      one: '1 rule',
    );
    return '$program $gameTitle ($_temp0)';
  }

  @override
  String get ruleSelectionSearchHint =>
      'Search by rule code (SG1, GG2...) or summary...';

  @override
  String get ruleSelectionNoMatchingRules => 'No matching rules found';

  @override
  String get ruleSelectionNoMatchingRulesSubtitle =>
      'Try searching for another rule code or keyword.';

  @override
  String get rulesViewInManual => 'View in Manual';

  @override
  String get rulesSearchQa => 'Search Q&A';

  @override
  String rulesProgramManual(String program) {
    return '$program Manual';
  }

  @override
  String get rulesOfficialQa => 'Official Q&A';

  @override
  String get rulesSearchHint =>
      'Search rules (e.g. G12, SG6, Pinning, Autonomous)';

  @override
  String get rulesNoMatchingRules => 'No matching rules found.';

  @override
  String get rulesNoMatchingRulesSubtitle =>
      'Try searching with a different rule code or keyword.';

  @override
  String get rulesDisclaimerBanner =>
      'DISCLAIMER:  These are a summary of the official rules and are only for reference - check the game manual before you make a ruling.';

  @override
  String get rulesDismissDisclaimerTooltip => 'Dismiss disclaimer';

  @override
  String get ruleGroupSpecificGame => 'Specific Game Rules';

  @override
  String get ruleGroupScoring => 'Scoring Rules';

  @override
  String get ruleGroupGeneralGame => 'General Game Rules';

  @override
  String get ruleGroupGeneral => 'General Rules';

  @override
  String get ruleGroupSafety => 'Safety Rules';

  @override
  String get ruleGroupRobot => 'Robot Rules';

  @override
  String get ruleGroupRobotSkills => 'Robot Skills Challenge Rules';

  @override
  String get ruleGroupTournament => 'Tournament Rules';

  @override
  String get ruleGroupVexUGame => 'VEX U Game Rules';

  @override
  String get ruleGroupVexURobot => 'VEX U Robot Rules';

  @override
  String get ruleGroupVexUSkills => 'VEX U Robot Skills Challenge Rules';

  @override
  String get ruleGroupVexUTournament => 'VEX U Tournament Rules';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeDescription =>
      'Select theme mode. Device mode automatically follows your operating system light or dark setting.';

  @override
  String get settingsThemeDevice => 'Device';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystemDefault => 'System Default';

  @override
  String get settingsRefereeSetupSection => 'Referee Setup';

  @override
  String get settingsRefereeNameLabel => 'Referee Display Name';

  @override
  String get settingsRefereeNameHint => 'e.g. Field 1 Head Referee';

  @override
  String get settingsSyncSharingSection => 'Sync & Sharing';

  @override
  String get settingsSharingNotEnabled => 'Sharing Not Enabled';

  @override
  String get settingsSharingNotEnabledDescription =>
      'Notes are stored locally on this device. Once sharing is enabled for this event, the share admin can configure and manage the sync server.';

  @override
  String get settingsSyncServerConfigSection => 'Sync Server Configuration';

  @override
  String get settingsSyncServerConfigAdminDesc =>
      'Connect to the cloud server or a server on your local network';

  @override
  String get settingsSyncServerConfigMemberDesc =>
      'Sync server is configured by the share admin for this event';

  @override
  String settingsManagedByHostNotice(String adminName) {
    return 'Managed by Host ($adminName). Only the share admin can configure the sync server for this event.';
  }

  @override
  String get settingsSyncServerModeLabel => 'Sync Server Mode';

  @override
  String settingsServerOptionCloud(String cloudUrl) {
    return 'Cloud Server ($cloudUrl)';
  }

  @override
  String get settingsServerOptionLan =>
      'Local Server (http://roboref.local:8080)';

  @override
  String get settingsServerOptionCustom => 'Custom Server URL';

  @override
  String get settingsCustomServerUrlHint =>
      'e.g. http://localhost:8080 or https://sync.roboref.app';

  @override
  String get settingsServerStatusLabel => 'Server Status:';

  @override
  String get settingsSyncStatusLabel => 'Sync Status:';

  @override
  String get settingsSyncingStatus => 'Syncing...';

  @override
  String get settingsIdleReadyStatus => 'Idle / Ready';

  @override
  String settingsDeviceUuid(String deviceId) {
    return 'Device UUID: $deviceId';
  }

  @override
  String settingsLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String settingsErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsTriggeredSyncSnackbar => 'Triggered background sync...';

  @override
  String get settingsSyncNowButton => 'Sync Now';

  @override
  String settingsTestingConnectionTo(String target) {
    return 'Testing connection to $target...';
  }

  @override
  String get settingsTestingDefaultTarget => 'server';

  @override
  String settingsConnectionSuccessful(String message) {
    return 'Connection successful: $message';
  }

  @override
  String settingsConnectionFailed(String message) {
    return 'Connection failed: $message';
  }

  @override
  String get settingsTestingButton => 'Testing...';

  @override
  String get settingsTestConnectionButton => 'Test Connection';

  @override
  String get settingsBadgeLocalhost => 'Local Server (localhost)';

  @override
  String get settingsBadgeVenueLan => 'Venue LAN (roboref.local)';

  @override
  String get settingsBadgeCloudServer => 'Cloud Server';

  @override
  String get settingsBadgeOffline => 'Offline / Unreachable';

  @override
  String get settingsBadgeChecking => 'Checking...';

  @override
  String get settingsEventInfoSection => 'Event Information';

  @override
  String get settingsVexEventsPage => 'VEX Events Page';

  @override
  String get settingsAboutSection => 'About RoboRef';

  @override
  String get settingsViewSourceItem => 'View Source';

  @override
  String get settingsPrivacyPolicyItem => 'Privacy Policy';

  @override
  String get settingsVersionCopied => 'Version copied to clipboard';

  @override
  String get settingsCurrentVersionTitle => 'Current Version';

  @override
  String get settingsCurrentVersionDescription =>
      'Use this to let a developer know what version you are using if you encounter an issue.';

  @override
  String get settingsExperimentalSection => 'Experimental Features';

  @override
  String get settingsExperimentalCheckboxLabel =>
      'Enable extra features that may not work as intended';

  @override
  String get settingsExperimentalWarningTitle =>
      'Warning!  Experimental Features!';

  @override
  String get settingsExperimentalWarningContent =>
      'Ticking this will enable extra features that may not work as intended';

  @override
  String get settingsImportEventDataSection => 'Import Event Data';

  @override
  String get settingsImportEventDataDescription =>
      'This feature is experimental and may not work as intended';

  @override
  String get settingsImportEventDataButton => 'Import Event Data (TM CSV)';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyOpenInBrowserTooltip => 'Open in Browser';

  @override
  String get privacyUnableToLoad => 'Unable to load privacy policy';

  @override
  String get privacyViewOnWebButton => 'View on roboref.app/privacy';

  @override
  String get privacyCouldNotOpenBrowser =>
      'Could not open https://roboref.app/privacy in browser.';

  @override
  String get privacyCouldNotOpenLink => 'Could not open web link.';

  @override
  String get eventShareTitle => 'Event Sharing & Sync';

  @override
  String get eventShareBadgeLocalOnly => 'LOCAL ONLY';

  @override
  String get eventShareLocalOnlyTitle =>
      'Notes are stored entirely locally on this device.';

  @override
  String get eventShareLocalOnlyDescription =>
      'To collaborate with alliance referees and scorekeepers, share this event online to synchronize notes in real time.';

  @override
  String get eventShareCheckingServerButton => 'Checking Server...';

  @override
  String get eventShareOrJoinExisting => 'OR JOIN AN EXISTING SHARE';

  @override
  String get eventShareEnterCodeLabel => 'Enter 6-Digit Share Code';

  @override
  String get eventShareEnterCodeHint => 'e.g. ABC123';

  @override
  String get eventShareJoinedSuccessSnackbar =>
      'Joined shared session successfully!';

  @override
  String get eventShareJoinButton => 'Join';

  @override
  String get eventShareConflictTitle => 'Existing Share Session Found';

  @override
  String eventShareConflictDescription(
      String sku, String adminName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'A shared session for $sku is already active on the network, hosted by $adminName with $count participants.',
      one:
          'A shared session for $sku is already active on the network, hosted by $adminName with 1 participant.',
    );
    return '$_temp0';
  }

  @override
  String eventShareJoinedAdminSessionSnackbar(String adminName) {
    return 'Joined $adminName\'s session';
  }

  @override
  String eventShareJoinAdminButton(String adminName) {
    return 'Join $adminName';
  }

  @override
  String get eventShareCreateSeparateAnywayButton =>
      'Create Separate Share Anyway';

  @override
  String eventShareSharingStatusAdmin(String serverType) {
    return 'Sharing: $serverType (Host / Admin)';
  }

  @override
  String eventShareSharingStatusMember(String serverType) {
    return 'Sharing: $serverType (Member)';
  }

  @override
  String eventShareAdminRoleDescription(String serverType) {
    return 'You are the admin on $serverType. You can invite referees and manage participants.';
  }

  @override
  String eventShareMemberRoleDescription(String adminName, String serverType) {
    return 'Hosted by $adminName on $serverType. Notes synchronize automatically.';
  }

  @override
  String get eventShareScanToJoinTitle => 'Scan to Join Share Session';

  @override
  String get eventShareCodeLabel => 'Share Code: ';

  @override
  String get eventShareCopyCodeTooltip => 'Copy Share Code';

  @override
  String get eventShareCodeCopiedSnackbar => 'Share code copied to clipboard!';

  @override
  String get eventShareJoinLinkCopiedSnackbar =>
      'Join link copied to clipboard!';

  @override
  String get eventShareCopyJoinLinkButton => 'Copy Join Link';

  @override
  String eventShareConnectedRefereesTitle(int count) {
    return 'Connected Referees ($count)';
  }

  @override
  String get eventShareNameHistoryTooltip => 'Referee name history';

  @override
  String get eventShareRefreshParticipantsTooltip => 'Refresh participant list';

  @override
  String get eventShareBadgeYou => 'You';

  @override
  String get eventShareBadgeAdmin => 'Admin';

  @override
  String eventSharePreviousNamesForTooltip(String refereeName) {
    return 'Previous names for $refereeName';
  }

  @override
  String eventShareRemoveParticipantTooltip(String refereeName) {
    return 'Remove $refereeName';
  }

  @override
  String get eventShareCloseAndDeleteButton => 'Close & Delete Share Session';

  @override
  String get eventShareAdminCannotLeaveNote =>
      'Note: The admin cannot leave until all other referees have left or been removed.';

  @override
  String get eventShareLeaveSharedEventButton => 'Leave Shared Event';

  @override
  String eventShareRemoveParticipantTitle(String refereeName) {
    return 'Remove $refereeName?';
  }

  @override
  String eventShareRemoveParticipantConfirm(String refereeName) {
    return 'Are you sure you want to remove $refereeName from this shared session? They will stop syncing new notes.';
  }

  @override
  String get eventShareCannotLeaveTitle => 'Cannot Leave Share';

  @override
  String eventShareCannotLeaveContent(int count) {
    return 'You cannot leave or close this session while $count other referees are connected. Please remove all participants first or wait for them to leave.';
  }

  @override
  String get eventShareCloseDeleteTitle => 'Close & Delete Share?';

  @override
  String get eventShareCloseDeleteContent =>
      'Closing the session will delete it from the sync server and purge cloud notes. Your local notes will remain safely on this device.';

  @override
  String get eventShareClosedDeletedSnackbar =>
      'Share session closed and cloud data deleted.';

  @override
  String get eventShareCloseDeleteConfirmButton => 'Close & Delete';

  @override
  String get eventShareLeaveEventTitle => 'Leave Shared Event?';

  @override
  String get eventShareLeaveEventContent =>
      'You will disconnect from this share session and stop receiving sync updates. Your local notes will remain on your device.';

  @override
  String get eventShareLeftEventSnackbar => 'Left shared event session.';

  @override
  String get eventShareLeaveEventConfirmButton => 'Leave Event';

  @override
  String get eventShareNameHistoryDialogTitle => 'Name History';

  @override
  String eventShareCurrentNameLabel(String refereeName) {
    return 'Current Name: $refereeName';
  }

  @override
  String get eventSharePreviousNamesLabel => 'Previous names at this event:';

  @override
  String get eventShareNoPreviousNamesForReferee =>
      'No previous names recorded for this referee at this event.';

  @override
  String get eventShareAllNameHistoryDialogTitle => 'Referee Name History';

  @override
  String get eventShareNoPreviousNamesForAny =>
      'No previous names recorded for any referee at this event.';

  @override
  String get eventShareNoPreviousNamesShort => 'No previous names';

  @override
  String get errorSyncServerUrlNotConfigured =>
      'Sync server URL is not configured';

  @override
  String errorServerRespondedWithStatus(int statusCode) {
    return 'Server responded with status $statusCode';
  }

  @override
  String get errorSkuCannotBeEmpty => 'SKU cannot be empty';

  @override
  String get errorCsvIsEmpty => 'CSV is empty';

  @override
  String errorFailedToParseTeamsCsv(String error) {
    return 'Failed to parse Teams CSV: $error';
  }

  @override
  String errorFailedToParseMatchesCsv(String error) {
    return 'Failed to parse Matches CSV: $error';
  }

  @override
  String errorServerReturnedError(int statusCode, String body) {
    return 'Server returned error $statusCode: $body';
  }

  @override
  String errorFailedToConnectVexEventsProxy(String error) {
    return 'Failed to connect to VEX Events proxy: $error';
  }

  @override
  String errorFailedToSearchEventsViaSyncServer(String error) {
    return 'Failed to search events via sync server: $error';
  }

  @override
  String errorCouldNotConnectToVexEvents(String error) {
    return 'Could not connect to VEX Events: $error';
  }

  @override
  String errorTournamentNotFoundOnVexEvents(String sku) {
    return 'Tournament \"$sku\" not found on VEX Events';
  }

  @override
  String errorFailedToFetchTournamentData(String error) {
    return 'Failed to fetch tournament data from sync server: $error';
  }

  @override
  String get errorFailedToLoadTournamentData =>
      'Failed to load tournament data';

  @override
  String get errorRefreshAlreadyInProgress => 'Refresh already in progress';

  @override
  String get errorProviderNotMounted => 'Provider not mounted';

  @override
  String get errorServerUrlIsEmpty => 'Server URL is empty';

  @override
  String get errorInvalidServerUrlFormat => 'Invalid server URL format';

  @override
  String get statusServerTypeLocal => 'Local Server';

  @override
  String get statusServerTypeVenueLan => 'Venue LAN';

  @override
  String get statusServerTypeCloud => 'Cloud Server';

  @override
  String statusConnectedToServer(String serverType, int latencyMs) {
    return 'Connected to $serverType ($latencyMs ms)';
  }

  @override
  String errorServerReachableHttpStatus(int statusCode) {
    return 'Server reachable but returned HTTP $statusCode';
  }

  @override
  String get errorCouldNotReachServer => 'Could not reach server';

  @override
  String get errorConnectionTimedOut =>
      'Connection timed out (server unreachable)';

  @override
  String get errorConnectionRefused => 'Connection refused / host unreachable';

  @override
  String get errorNetworkOrCors => 'Network or CORS error connecting to server';

  @override
  String errorFailedToCreateShareHttp(int statusCode) {
    return 'Failed to create share session (HTTP $statusCode)';
  }

  @override
  String get errorAdminCannotLeaveWithActiveParticipants =>
      'The admin cannot leave while other referees are in the session.';

  @override
  String get errorFailedToLeaveShare => 'Failed to leave share session';

  @override
  String get errorControllerDisposed => 'Controller disposed';

  @override
  String get errorFailedToCreateShare => 'Failed to create share';

  @override
  String get errorCouldNotJoinShareSession =>
      'Could not join share session. Check code or connection.';

  @override
  String get errorFailedToRemoveParticipant => 'Failed to remove participant';

  @override
  String get errorRemovedFromSharedSession =>
      'You were removed from this shared event session.';
}
