## 18 August 2026

- **Important**: Old installs of RoboRef will need updating to this version to work correctly.
- Backend hosting changes
- API addresses have changed
- Simplified reports and data export addresses to `/export/:sku/...`
- Added more tests

## 17 August 2026

- Improved Team Info page
- You can now always set your Display Name from the Manage tab
- Fixed bug where Display Names sometimes wouldn't accept spaces
- Migrated frontend and sync API hosting into a unified Cloudflare Worker with Static Assets for faster same-origin API calls

## 16 August 2026

- Fixed asset loading and MIME type errors after deploying app updates
- Added status and error messages on Schedule, Matches, and Teams tabs when VEX Events data cannot be loaded or when schedules/teams have not been published yet
- Fixed infinite spinner state on Matches tab when no matches exist
- Updated dependencies

## 13 August 2026

- Security and performance improvements
- Added build tests

## 11 August 2026

- Improved search for Schedule and Teams tabs
- Minor UI improvements

## 10 August 2026

- Fixed package issue, and renamed internal packages
- Updated dependencies

## 06 August 2026

- Display red alliance teams above blue alliance teams on the matches tab
- Fixed layout issue meaning notes couldn't be added to an IQ match
- Fixed crashes after an update

## 05 August 2026

- Added option to undelete notes directly with a single click when previewing deleted notes
- Added more events to note history
- Fixed note deletion
- Updated dependencies

## 03 August 2026

- RoboRef preloads pages and caches data for longer for improved speed
- Improved match timer UI
- Make photo UI consistent with the rest of the app
- Make note preview UI consistent with the rest of the app
- Can add new pictures when editing a note
- Cleaned up obsolete code

## 02 August 2026

- Reimplemented photo uploads
- Add icons to notes
- Bug fixes

## 01 August 2026

- Added viewing options to QR code viewer: Stylised, Standard and HDR (on supported devices)
- Fixed invite URL and QR code to consistently use roboref.fyi links
- Bug fixes

## 31 July 2026

- Updated user interface labels to use Note/Notes consistently
- Allow notes to be undeleted, this is tracked via note history.
- Renamed 'Update Log' to 'Change Log' across navigation and headers
- Only show Change Log on load if there have been changes added to it
- UI tweaks for usability

## 29 July 2026

- Allow event names/organisations to go across multiple lines on the home screen and search
- Fixed Team Info screen and made UI consistent
- Added consistent pills across all notes lists
- Added an automatic fix for a crash scenario

## 28 July 2026

- Added event search filters
- Added more data to event search
- Removed geolocation from search
- UI bug fixes
- Updated dependencies

## 26 July 2026

- Updated home screen layout
- Updated rules page
- Updated Match Notes
- Updated Event 
- Renamed 'Entry'/'Incident' to 'Note' for consistency
- Renamed 'Update Notes' to 'Update Log'
- Renamed 'Isolate Team' to 'View all *teamnumber* notes'
- Changed the user prompt for search
- Removed hidden events viewer
- Removed forced upper case from search
- Changed some icons as they were similar
- Improved UI consistency
- Removed unused code
- Bug fixes

## 25 July 2026

- Added a QR code and link for inviting users directly to an event
- Improved UI consistency
- Shortened load times
- Bug fixes

## 24 July 2026

- Moved the VEX Events link to the events page
- Updated the contact us page
- Updated API domain
- Renamed code for better organisation
- Removed unused code

## 23 July 2026

- Added title bar and share button to the main page
- Added rules to the events navigation
- Separate event and matches in the event navigation
- Add scheduled time to matches
- Update timer logic on matches
- Rounded connection times to the nearest millisecond
- Improved UI consistency
- Made back/home/x behaviour more consistent/predictable
- Fixed UI alignment issues

## 22 July 2026

- Added hide event button to tidy up the home screen
- Added VEX Events link (for event info) on Event Manage screen
- Worked on UI consistency/enhancements
- Updated dependencies
- Bug fixes

## 19 July 2026

- Added a light/dark/system theme toggle
- Added Q&A search
- Fixed rules viewer
- Updated dependencies

## 26 June 2026

- Backend updates

## 22 June 2026

- Enabled data caching

## 21 June 2026

- Updated the Contact form
- Backend changes

## 20 June 2026

- This includes some breaking changes to the backend - old installs of RoboRef will need updating to this version to work correctly.

## 19 June 2026

- Rewired the Sentry automated error reporting

## 15 June 2026

- Updated the logo
- Backend changes and optimisations

## 13 June 2026

- Rebranded from Referee.FYI to RoboRef
- Update the API to connect to events.vex.com

## Initial Release

- RoboRef is a fork of the 1st March 2025 build of Referee.FYI (from before the repository was made private).  RoboRef is designed to work with VEX Robotics Competition tournaments.
