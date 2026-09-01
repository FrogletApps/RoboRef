# RoboRef

[![Platform - Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![Backend - Hono](https://img.shields.io/badge/Backend-Hono%20%7C%20TypeScript-E36002?logo=typescript)](https://hono.dev)
[![Database - SQLite / Drift](https://img.shields.io/badge/Database-SQLite%20%7C%20Drift-003B57?logo=sqlite)](https://drift.simonbinder.eu)
[![UI - Material 3](https://img.shields.io/badge/UI-Material%20Design%203-7B1FA2)](https://m3.material.io)

**RoboRef** ([roboref.app](https://roboref.app)) is an offline-first match anomaly log and referee assistant built specifically for Head Referees and field referees at VEX Robotics competitions (**V5RC**, **VIQRC**, **VEX U**, and **VEX AI**).

RoboRef enables field referees to quickly log rule infractions, inspect a team's prior incident history before match queuing, and synchronize notes seamlessly across peer devices in real-time—even in tournament venues with severe RF interference and zero internet connectivity.

---

## 📑 Table of Contents

- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started & Running Locally](#-getting-started--running-locally)
  - [1. Flutter Client (`app/`)](#1-flutter-client-app)
  - [2. Universal Sync Server (`server/`)](#2-universal-sync-server-server)
- [Building for Production](#-building-for-production)
  - [Using Automated Build Scripts](#using-automated-build-scripts)
  - [Manual Flutter Builds](#manual-flutter-builds)
  - [Deploying the Sync Server](#deploying-the-sync-server)
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
| **State Management** | **Riverpod** 2.x | Reactive state and dependency injection |
| **Client Storage** | **Drift** (SQLite) | Embedded, high-performance offline database |
| **Sync Server** | **Hono** + **TypeScript** | Universal backend running on Node.js (LAN) and Cloudflare Workers (Cloud) |
| **Server Storage** | **better-sqlite3** / **Cloudflare D1** | High-speed server persistence and delta sync logging |

---

## 📂 Repository Structure

```text
RoboRef/
├── app/                  # Flutter client application
│   ├── android/          # Android platform files & gradle configuration
│   ├── ios/              # iOS platform files & Xcode workspace
│   ├── web/              # Web platform assets, manifest, and service worker
│   ├── assets/           # Application icons, fonts, and changeLog.md
│   └── lib/
│       ├── core/         # Network clients, themes, constants, and utilities
│       ├── database/     # Drift SQLite schemas, DAOs, and connection logic
│       └── features/     # Feature-first modules (incidents, matches, teams, settings, home)
├── server/               # Universal sync backend (TypeScript & Hono)
│   └── src/
│       ├── adapters/     # Storage implementations (better-sqlite3 for Node, D1 for Cloudflare)
│       ├── core/         # REST API routes, VEX Events proxy, and sync logic
│       ├── index.node.ts # Local Node.js / Raspberry Pi server entry point
│       └── index.cf.ts   # Cloudflare Workers server entry point
├── scripts/              # Build and utility scripts
│   ├── build.ps1         # Automated Windows / PowerShell build script (CalVer + commit count)
│   ├── build.sh          # Automated Bash / Linux build script
│   ├── deploy.ps1        # Automated build + deploy script for Cloudflare (test/live)
│   ├── deploy.sh         # Automated Linux / Bash deploy script for Cloudflare
│   └── generate-icons.mjs# Icon generation pipeline for Android, iOS, and Web assets
└── wrangler.toml         # Root Cloudflare configuration (Workers + Static Web Assets, test/live)
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

### 2. Universal Sync Server (`server/`)

The sync server can run locally as a Node.js process (ideal for Raspberry Pi venue servers or local debugging) or inside the Cloudflare Workers local environment.

Navigate to the `server/` directory and install dependencies:

```bash
cd server
npm install
```

#### Run Local Venue / LAN Server (Node.js)
Starts the local server on `http://0.0.0.0:8080` backed by a local SQLite database file (`roboref.sqlite`):
```bash
npm run dev:node
```

#### Run Cloudflare Worker Locally (Wrangler)
```bash
npm run dev:cf
```

#### Server Typecheck
```bash
npm run typecheck
```

---

## 📦 Building for Production

### Using Automated Build Scripts

RoboRef uses Calendar Versioning (**CalVer**, formatted as `YYYY.M.D`) paired with the Git commit count as the build number. Helper scripts in `scripts/` automatically format these flags:

#### Windows (PowerShell)
```powershell
# Build Android APK (default target: apk)
.\scripts\build.ps1 apk

# Build / Typecheck Sync Server & Cloudflare Worker
.\scripts\build.ps1 server

# Build both Android APK and Server
.\scripts\build.ps1 all

# Build other Flutter targets
.\scripts\build.ps1 appbundle
.\scripts\build.ps1 web
.\scripts\build.ps1 windows
```

#### Linux / macOS (Bash)
```bash
# Build Android APK (default target: apk)
./scripts/build.sh apk

# Build / Typecheck Sync Server & Cloudflare Worker
./scripts/build.sh server

# Build both Android APK and Server
./scripts/build.sh all

# Build other Flutter targets
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

### Deploying to Cloudflare (Web App + Sync Server)

RoboRef uses a unified Cloudflare Workers configuration with **Static Assets** (`wrangler.toml` at the repository root). This hosts the **Flutter Web PWA** on Cloudflare's global edge network while routing backend API requests (`/api/*`) directly to the Hono sync worker.

Ensure you are logged into Wrangler (`npx wrangler login`) before deploying.

#### 1. Automated Build & Deploy Scripts

##### Windows (PowerShell)
```powershell
# Build Server & Web, then deploy to Test environment (test D1 database)
.\scripts\deploy.ps1 test

# Build Server & Web, then deploy to Live environment (roboref.app + live D1 database)
.\scripts\deploy.ps1 live

# Deploy existing build without rebuilding
.\scripts\deploy.ps1 test -SkipBuild

# Deploy without rebuilding Flutter Web (e.g. server-only updates)
.\scripts\deploy.ps1 test -SkipWebBuild

# Deploy without rebuilding Server (e.g. web-only updates)
.\scripts\deploy.ps1 test -SkipServerBuild
```

##### Linux / macOS (Bash)
```bash
# Build Server & Web, then deploy to Test
./scripts/deploy.sh test

# Build Server & Web, then deploy to Live
./scripts/deploy.sh live

# Deploy with skip options
./scripts/deploy.sh test --skip-build
./scripts/deploy.sh test --skip-web
./scripts/deploy.sh test --skip-server
```

#### 2. Direct Wrangler CLI Commands
```bash
# Test environment
npx wrangler deploy --env test

# Live / Production environment
npx wrangler deploy --env live
```

---

### Deploying the Venue Server (Raspberry Pi / LAN)

#### Raspberry Pi / Linux Venue Server (Native Node.js)
```bash
cd server
npm run build:node
npm run start:node
```
*(Optionally configure systemd or PM2 to keep the Node.js server active on boot at `http://roboref.local:8080`.)*

#### Raspberry Pi / Linux Venue Server (Docker)
Build and run the lightweight Alpine-based container with persistent SQLite storage:
```bash
cd server
docker build -f Dockerfile.rpi -t roboref-sync-server .
docker run -d -p 8080:8080 -v roboref-data:/data --restart unless-stopped --name roboref-sync roboref-sync-server
```

---

## ⚙️ Configuration & Environment Variables

### Server Environment Variables

Create a `.env` file inside the `server/` folder or set environment variables on your deployment host:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `8080` | Port for the local Node.js sync server |
| `DB_PATH` | `roboref.sqlite` | Filepath for the local SQLite database |
| `VEX_EVENTS_TOKEN` | *(Optional)* | VEX Events API v2 Bearer token for server-side proxy caching |
| `VEX_API_KEY` | *(Optional)* | Alternative environment variable name for VEX Events API key |

### In-App Client Settings

Inside the RoboRef app under **Settings**:
- **Referee Display Name**: Configure referee display name. Active tournaments are selected from the Event List on the Home screen.
- **Sync Server Address**: Configure the sync server host (defaults to `http://roboref.local:8080` for venue LAN). All VEX Events queries proxy securely through the sync server.

---

## 🧪 Testing & Code Quality

### Flutter Client Tests
```bash
cd app
flutter test
flutter analyze
```

### Server Typecheck
```bash
cd server
npm run typecheck
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
