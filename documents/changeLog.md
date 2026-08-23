# Change Log

## 23 August 2026

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter & Dart for cross-platform Android, iOS, and Web.
- **Match Schedule & Field Inspection**: Added full tournament match schedule view with alliance team indicators and field inspection links.
- **VEXEvents API Integration**: Direct retrieval of tournament match schedules and team rosters by SKU.
- **Tournament Manager (TM) CSV Import**: Added support for manual paste/import of Tournament Manager team and match schedule CSVs for offline venue readiness.
- **Venue LAN Sync Priority (`roboref.local`)**: Set `http://roboref.local:8080` as the preferred default connection with automatic LAN server status detection.
- **Universal Sync Server**: TypeScript + Hono sync server for both local Raspberry Pi venue deployment and Cloudflare Workers cloud deployment.
- **Brand Identity & Icon Assets**: Integrated canonical RoboRef logo across in-app UI, Web PWA icons/favicons, Android mipmaps, and iOS AppIcon set.
- **Change Log Screen**: Dynamic in-app changelog viewer loading and rendering release notes directly from `documents/changeLog.md` with version copy and search filtering.
