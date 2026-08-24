# Change Log

## 2026.8.24+1

- **Live VEX Events API Integration**: Connected official VEX Events API (`events.vex.com/api/v2`) replacing placeholder dummy events with live event discovery and schedule ingestion.
- **Server-Side RobotEvents Proxy**: Added `/api/vexevents/*` proxy endpoint to the universal sync server with in-memory TTL caching and server-side Bearer token injection.
- **In-App API Key Configuration**: Added dedicated VEX Events API Key management in Settings with real-time test validation and persistent local storage.
- **Multi-Division Tournament Ingestion**: Automated retrieval and persistence of all division match schedules and complete team rosters into local SQLite database upon event selection.
- **Event Picker Live Search & Debounce**: Added live debounced search by SKU or tournament name with program filters (V5RC, VIQRC, VEX U, VEX AI) and offline cached fallback.

## 2026.8.23+1

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter & Dart for cross-platform Android, iOS, and Web.
- **Match Schedule & Field Inspection**: Added full tournament match schedule view with alliance team indicators and field inspection links.
- **VEXEvents API Integration**: Direct retrieval of tournament match schedules and team rosters by SKU.
- **Tournament Manager (TM) CSV Import**: Added support for manual paste/import of Tournament Manager team and match schedule CSVs for offline venue readiness.
- **Venue LAN Sync Priority (`roboref.local`)**: Set `http://roboref.local:8080` as the preferred default connection with automatic LAN server status detection.
- **Universal Sync Server**: TypeScript + Hono sync server for both local Raspberry Pi venue deployment and Cloudflare Workers cloud deployment.
- **Brand Identity & Icon Assets**: Integrated the RoboRef logo across in-app UI, Web PWA icons/favicons, Android mipmaps, and iOS AppIcon set.
- **Functional Share QR Code**: Replaced placeholder mock graphics with a fully scannable QR code linking to `https://roboref.fyi` on the Share RoboRef screen.
- **Change Log Screen**: Dynamic in-app changelog viewer loading and rendering release notes directly from `documents/changeLog.md` with version copy and search filtering.
- **Dynamic App Versioning & CalVer**: Connected Change Log version card to runtime platform package info (`package_info_plus`) with automated date-based versioning and Git commit count build numbers.
- **Home Screen Cleanup**: Removed the 'Browse All' button, eliminated the loading spinner, and hid the 'Recent Tournaments' header when no events exist to prominently show the 'Welcome to RoboRef!' note.
- **Hierarchical Navigation & Event Workspace**: Adopted Material Design 3 guidelines by removing persistent bottom navigation from the Home hub screen and introducing a dedicated Event Workspace with contextual bottom tabs (Incidents, Matches, Teams, Settings) and top back navigation.
- **VEX Program Filtering**: Added VEX AI (`VAIRC`) to event program filter options and preloaded championship events, alongside V5RC, VIQRC, and VEX U.
