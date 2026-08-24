# RoboRef — Flutter Client Application

This directory (`app/`) contains the Flutter client for **RoboRef**, targeting Android, iOS, and Web/PWA.

For full project documentation, architecture details, build scripts, and server setup, see the main [Repository README.md](../README.md).

## Quick Start (Flutter Client)

```bash
# Install dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Run on Android device / emulator
flutter run -d android

# Run tests
flutter test

# Run analyzer
flutter analyze

# Re-generate Drift SQLite code
dart run build_runner build --delete-conflicting-outputs
```
