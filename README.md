# RoboRef

[![Platform - Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![Backend - Hono](https://img.shields.io/badge/Backend-Hono%20%7C%20TypeScript-E36002?logo=typescript)](https://hono.dev)
[![Database - SQLite / Drift](https://img.shields.io/badge/Database-SQLite%20%7C%20Drift-003B57?logo=sqlite)](https://drift.simonbinder.eu)
[![UI - Material 3](https://img.shields.io/badge/UI-Material%20Design%203-7B1FA2)](https://m3.material.io)

**RoboRef** is a match anomaly log and referee assistant built specifically for Head Referees at VEX Robotics competitions (**V5RC**, **VIQRC**, **VEX U**, and **VEX AI**).

RoboRef enables referees to quickly log rule violations, check a team's information, and synchronise notes seamlessly across devices in real-time.

RoboRef is available for Android on [Google Play](https://play.google.com/store/apps/details?id=app.roboref), and on the web at [roboref.app](https://roboref.app).

---

## 📑 Table of Contents

- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started & Running Locally](#-getting-started--running-locally)
  - [1. Flutter Client (`app/`)](#1-flutter-client-app)
  - [2. Sync & API Server (`RoboAppsServer`)](#2-sync--api-server-roboappsserver)
- [Building for Production](#-building-for-production)
  - [Using Automated Build Scripts](#using-automated-build-scripts)
  - [Manual Flutter Builds](#manual-flutter-builds)
  - [Deploying the Web PWA to Cloudflare](#deploying-the-web-pwa-to-cloudflare)
- [Configuration & Environment Variables](#-configuration--environment-variables)
- [Testing & Code Quality](#-testing--code-quality)
- [Versioning & Changelog](#-versioning--changelog)
- [Contributing & AI Agent Guidelines](#-contributing--ai-agent-guidelines)

---

## ✨ Key Features

- ⚡ **Offline-First Resilience**: Full local persistence using **Drift** (SQLite). Referees can log notes, search matches, and inspect team histories without any network connection.
- 📝 **Fast Incident Logging**: Rapidly record rule infractions with rule codes (e.g. `G1`, `G12`, `S1`, `SG6`, `R4`), severity classifications (*Minor*, *Major*, *Warning*, *DQ*), match linkage, and referee notes.
- 🔍 **Prior Infraction History**: View cumulative incident histories for every team on the field prior to match start to spot repeat warnings or escalating patterns.
- 🏆 **Tournament & Division Schedules**: Ingest complete tournament schedules, division assignments, alliance pairings, and match field allocations.
- 🌐 **VEX Events API & CSV Ingestion**:
  - Direct live search and schedule ingestion via the official **VEX Events API v2** (`events.vex.com`).
  - Offline Tournament Manager (TM) team and match schedule CSV import for venues without internet access.
- 🔄 **Dual Sync Protocol**:
  - **Venue LAN Sync**: Connect to a local venue Raspberry Pi or laptop (`http://roboref.local:8080`) over local Wi-Fi / Ethernet without WAN access.
  - **Cloud Sync**: Global replication powered by Cloudflare Workers and D1 database.
- 📱 **Mobile-First Material Design 3**: High-contrast, touch-friendly UI designed for rapid handheld operation on the competition field with full dark/light theme support.

---

## 🏗 Architecture & Tech Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Client** | **Flutter** (Dart ^3.5.0) | Cross-platform mobile (Android, iOS) & Web/PWA client |
| **State Management** | **Riverpod** 3.x | Reactive state and dependency injection |
| **Client Storage** | **Drift** (SQLite) | Embedded, high-performance offline database |
| **Web Hosting Worker** | **Cloudflare Workers** | Minimal static asset & `/privacy` endpoint wrapper (`worker/`) |
| **Sync & API Server** | **RoboApps Server** (separate repo) | Universal Hono/TypeScript backend on Cloudflare Workers (D1) & Node.js/Raspberry Pi (SQLite) |

---

## 📂 Repository Structure

```text
RoboRef/
├── app/                  # Flutter client application
│   ├── android/          # Android platform files & gradle configuration
│   ├── ios/              # iOS platform files & Xcode workspace
│   ├── web/              # Web platform assets, manifest, and service worker
│   ├── assets/           # Application icons, fonts, privacy.md, and changeLog.md
│   └── lib/
│       ├── core/         # Network clients, themes, constants, and utilities
│       ├── database/     # Drift SQLite schemas, DAOs, and connection logic
│       └── features/     # Feature-first modules (incidents, matches, teams, settings, home)
├── worker/               # Minimal Cloudflare Worker for Web PWA static assets & /privacy
│   ├── index.ts          # Request router (/privacy + ASSETS fallback)
│   ├── privacy.ts        # Markdown-to-HTML renderer for app/assets/privacy.md
│   └── privacy.test.ts   # Node built-in test suite for the /privacy worker
├── scripts/              # Build and utility scripts
│   ├── build.ps1         # Automated Windows / PowerShell Flutter build script (CalVer + commit count)
│   ├── build.sh          # Automated Bash / Linux Flutter build script
│   ├── deploy.ps1        # Automated Web PWA build + deploy script for Cloudflare (test/live)
│   ├── deploy.sh         # Automated Linux / Bash Web PWA deploy script for Cloudflare
│   └── generate_icons.py # Icon generation pipeline for Android, iOS, and Web assets
└── wrangler.toml         # Root Cloudflare configuration (Web PWA Static Assets + /privacy worker)
```

---

## 📋 Prerequisites

Before getting started, make sure you have installed:

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (`^3.5.0` or higher) with Dart `^3.5.0`
- **[Node.js](https://nodejs.org/)** (`v18.x` or `v20.x` LTS) and `npm`
- **Platform Toolchains** (depending on your target build):
  - **Android**: Android Studio & Android SDK (API 34+)
  - **iOS/macOS**: Xcode (macOS only)
  - **Web**: Google Chrome / Chromium

---

## 🚀 Getting Started & Running Locally

### 1. Flutter Client (`app/`)

Navigate to the `app/` directory and install Flutter dependencies:

```bash
cd app
flutter pub get
```

#### Run on Web (Chrome)
```bash
flutter run -d chrome
```

#### Run on Android Device or Emulator
```bash
flutter run -d android
```

#### Run on iOS Simulator (macOS)
```bash
flutter run -d ios
```

#### Code Generation (Drift Database / Models)
If you update database tables, DAOs, or queries, re-generate the Drift code:
```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

### 2. Sync & API Server (`RoboAppsServer`)

The universal sync, share, and VEX Events proxy server lives in the separate **RoboApps Server** repository (`RoboAppsServer`), deployable both to Cloudflare Workers (`/api/*` routes on `roboref.app` / `test.roboref.app`) and as a local Node.js / Docker venue server (`http://roboref.local:8080`).

---

## 📦 Building for Production

### Using Automated Build Scripts

RoboRef uses Calendar Versioning (**CalVer**, formatted as `YYYY.M.D`) paired with the Git commit count as the build number. Helper scripts in `scripts/` automatically format these flags:

#### Windows (PowerShell)
```powershell
# Build Android APK (default target: apk)
.\scripts\build.ps1 apk

# Build other Flutter targets
.\scripts\build.ps1 appbundle
.\scripts\build.ps1 web
.\scripts\build.ps1 windows
```

#### Linux / macOS (Bash)
```bash
# Build Android APK (default target: apk)
./scripts/build.sh apk

# Build other Flutter targets
./scripts/build.sh appbundle
./scripts/build.sh web
```

---

### Manual Flutter Builds

You can also run Flutter build commands directly from the `app/` folder:

```bash
cd app

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web PWA (outputs to app/build/web)
flutter build web --release

# iOS (requires macOS and Xcode)
flutter build ipa --release
```

---

### Deploying the Web PWA to Cloudflare

RoboRef deploys its **Flutter Web PWA** via Cloudflare Workers Static Assets (`wrangler.toml` at the repository root), paired with a minimal Worker in `worker/` solely to render `/privacy` from `app/assets/privacy.md`. Backend `/api/*` traffic is routed to the standalone **RoboApps Server** Worker.

Ensure you are logged into Wrangler (`npx wrangler login`) before deploying.

#### 1. Automated Build & Deploy Scripts

##### Windows (PowerShell)
```powershell
# Build Web PWA and deploy to Test environment (test.roboref.app)
.\scripts\deploy.ps1 test

# Build Web PWA and deploy to Live environment (roboref.app)
.\scripts\deploy.ps1 live

# Deploy existing app/build/web artifacts without rebuilding
.\scripts\deploy.ps1 test -SkipBuild
```

##### Linux / macOS (Bash)
```bash
# Build Web PWA and deploy to Test
./scripts/deploy.sh test

# Build Web PWA and deploy to Live
./scripts/deploy.sh live

# Deploy existing build without rebuilding
./scripts/deploy.sh test --skip-build
```

#### 2. Direct Wrangler CLI Commands
```bash
# Test environment
npx wrangler deploy --env test

# Live / Production environment
npx wrangler deploy --env live
```

---

## ⚙️ Configuration & Environment Variables

### In-App Client Settings

Inside the RoboRef app under **Settings**:
- **Referee Display Name**: Configure referee display name. Active tournaments are selected from the Event List on the Home screen.
- **Sync Server Address**: Configure the sync server host (e.g. `https://roboref.app`, or `http://roboref.local:8080`). All VEX Events queries proxy securely through the sync server.

---

## 🧪 Testing & Code Quality

### Flutter Client Tests
```bash
cd app
flutter test
flutter analyze
```

### Web Worker Tests (`/privacy`)
```bash
npm run test:worker
```

---

## 📅 Versioning & Changelog

- **CalVer Scheme**: Releases follow `YYYY.M.D+<commit_count>` (e.g. `2026.8.27+1`).
- **In-App Changelog**: RoboRef dynamically renders release notes directly from [app/assets/changeLog.md](app/assets/changeLog.md) inside the application.

---

## 🤝 Contributing & AI Agent Guidelines

When modifying or extending RoboRef:

1. **Clean-Slate Architecture**: All code is built fresh with Flutter/Dart and TypeScript/Hono. Do not use legacy referee.fyi code.
2. **Offline-First Constraint**: All user interactions must function completely offline and sync gracefully when connectivity is re-established.
3. **Changelog Requirement**: Any user-facing change (UI adjustments, features, bug fixes) must be documented in [app/assets/changeLog.md](app/assets/changeLog.md) under the current release/date.
4. **AI Guidelines**: Review [AGENTS.md](AGENTS.md) for full context and instructions when using AI coding assistants.

---
