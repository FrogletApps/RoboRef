# Change Log

## 2026.10.16+179

- **Refresh Matches & Teams**: Added reload icon in the AppBar and pull-down gesture to refresh matches and teams lists with an animated indicator.
- **Event Share Icon & Status Badge**: Replaced the admin shield/cloud icon in the event header with a persistent share icon with live participant count badge and status indicator.
- **Settings Version Layout**: Made version display and copy button responsive on smaller devices to prevent cutoff.
- **GitHub Repository Link**: Added link to RoboRef GitHub repository in Settings.
- **Security update**: Added CORS restrictions
- **Update Dependencies**

## 2026.10.15+166

- **Update Dependencies**

## 2026.10.13+165

- **App Display Name**: Set the launcher and display name to "RoboRef" on Android and iOS.

## 2026.10.11+157

- **Section Dividers**: Added dividers between all sections in the Settings and Manage & Sync pages.
- **Settings Layout**: Removed Advanced Settings label, moved Sync & Sharing above Event Information, and added divider before About RoboRef.
- **Event-Scoped Sync Server**: Removed Sync Server Configuration from the main settings page. Sync server settings are now saved per event and only visible on the event manage page when sharing is enabled, with configuration control reserved for the share admin.
- **Change Log & Version Display Moved**: Moved the Change Log and app version display into the Settings "About RoboRef" section, and removed Change Log from the home screen quick actions.

## 2026.10.10+156

- **Referee Name Synchronization**: Updating your referee name now updates across connected shared events for all referees.
- **Referee Name History**: Added info button to connected referees section to view previous names for referees at an event.

## 2026.10.05+155

- **Manage Page Updates**: Renamed "About" to "About RoboRef" and added "Event Information" section with link to VEX Events page.
- **Experimental Features Setting**: Added an Experimental Features toggle in Settings for local and test deployments to gate local data import buttons.
- **Game Rules V2 Updates**: Updated V5RC and VIQRC game rules to Version 2.0.
- **Update Dependencies**

## 2026.9.20+115

- **Empty State Icons**: Updated empty state placeholder icons to match bottom navigation tab icons.

## 2026.9.7+114
- **Dismiss Rules Disclaimer**: Made the rules disclaimer banner dismissable per event.
- **Update Icons**: Updated some icons to better match what they do.

## 2026.9.6+112

- **UI Terminology**: Renamed "Log Incident" to "Add Note" and simplified incident-related labels throughout the app.
- **Note Types**: Replaced severity selector with Note Type picker (General, Minor, Major, Inspection, Disabled) with consistent sizing that no longer overflows on small screens.
- **VE Event Support**: Added compatibility for `VE-` tournament event codes (like `VE-IQ` and `VE-V5`) and 5-digit event identifiers.
- **Default Sync Server**: Live deployments and Android app now default to the Cloud Server (roboref.app).
- **Cached Event List**: Load event data from local cache with automatic background updates when online.
- **Android Adaptive Icon**: Fixed the app icon on Android
- **Update dependencies**

## 2026.9.4+107

- **Backend changes**: Adding Android support

## 2026.9.2+102

- **Added Privacy Policy**: Viewable in the app and web version.

## 2026.9.1+1

- **Background Sync Polling**: Automatically checks for remote note updates every 60 seconds and on app resume.
- **Team Rankings**: Display tournament rankings in the icon avatar on the teams page.

## 2026.8.31+80

- **Bugfix**: Join links generated in test environment now correctly link to test.roboref.app.

## 2026.8.31+1

- **Secure Event Sharing**: The default is local only notes, but event data can be shared.
- **Rules Disclaimer**: Added disclaimer banner
- **Rules UI Cleanup**
- **Match UI Cleanup**
- **Improved note taking**: All rules can be selected and added to a note.
- **Update dependencies**

## 2026.8.27+1

- **Consistent Match Naming**: Standardized VEX IQ and V5 match labels to Qualification and Finals across schedules and imports.
- **Fix Match Sorting**: Matches display in chronological order
- **Fix Team Sorting**: Smaller team numbers show first (eg 99X before 101F)
- **Note Reporting Improvements**
- **Misc UI Improvements**

## 2026.8.26+1

- **Search Improvements**
- **Fixed Event Filters**: Can search by event type or region, with selected filters remembered across app sessions.
- **Fixes for testing locally**
- **Theme Improvements**: A new colour scheme with light and dark modes.

## 2026.8.25+1

- **Misc backend updates**

## 2026.8.24+1

- **Rename to roboref.app**: FYI is a bit of a mouthful - who'd want that in their app's name 😉
- **Misc UI Improvements**
- **Search Upgrade**: Can request more search results
- **VEX Events API Integration**

## 2026.8.23+1

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter & Dart.