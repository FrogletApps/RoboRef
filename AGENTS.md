# RoboRef AI Agent Guidelines & Context (`AGENTS.md`)

Welcome! This file (`AGENTS.md`) contains primary guidelines and context for AI coding agents working on the RoboRef codebase.

---

## 1. Project Overview

**RoboRef** ([roboref.app](https://roboref.app)) is an offline-first match anomaly log and referee assistant for Head Referees at VEX Robotics competitions. It enables referees to quickly log incidents, view prior team incident histories before matches, and synchronize notes seamlessly across field referee devices in real-time.

### Tech Stack & Architecture
- **Frontend (`app/`)**: Flutter & Dart (Android first, iOS, and Web/PWA) using **Drift** (SQLite) for offline-first data persistence and **Riverpod** for state management.
- **Sync Server (`server/`)**: Universal backend built with **TypeScript & Hono**, designed to run both as a **Cloudflare Worker** (cloud sync) and as a **Raspberry Pi / Linux local server** (LAN offline sync at tournament venues).

---

## 2. Crucial Guidelines for AI Agents

When assisting with code modifications or feature implementations, AI agents **MUST** follow these core guidelines:

### A. User-Facing Changes & Change Log
- **Changelog Requirement**: Whenever making a change that affects the end user (UI modifications, new features, bug fixes impacting user interaction, UX improvements), you **MUST** add an entry to `documents/changeLog.md` under a heading with the current date (formatted as `## DD Month YYYY`, e.g. `## 23 August 2026`).

### B. Clean Slate & Zero Legacy Code Reuse
- Do not reuse or copy code from the legacy referee.fyi implementation. All models, widgets, and sync protocols must be written clean from scratch.

### C. Offline-First & Low-Bandwidth Constraints
- RoboRef is designed for mobile devices in event venues with poor or non-existent internet connectivity.
- All user actions must function offline and gracefully reconcile when connectivity returns.
- Support both local LAN sync (`roboref.local:8080`) and Cloudflare Workers cloud sync.

### D. Touch-Friendly & Mobile-First UI
- Prioritize touch-friendly, small-screen mobile layouts.
- Ensure high contrast, clear visual feedback, and fast referee workflows on the field.

### E. Material Design 3 Principles
- Follow **Material Design 3 (M3)** principles and component guidelines across all UI implementations, styling, and navigation patterns unless specifically guided not to.

### F. Environment & Deployment Guardrails
- **Test Environment Only**: AI agents may build, test, and deploy ONLY to the **Test** environment (e.g. `npm run deploy:cf:test` inside `server/`, `wrangler deploy -c ../wrangler.toml --env test`, `test.roboref.app`, or `test.roboref.fyi`).
- **Live / Production Protection**: AI agents are strictly **PROHIBITED** from executing production deployment commands (e.g. `npm run deploy:cf:live`, `wrangler deploy --env live`) or modifying live production infrastructure directly. Production deployments must be executed or triggered manually by the maintainer.

---

## 3. Key Development Commands

```bash
# Flutter Client (in app/)
cd app
flutter pub get
flutter run -d chrome --web-renderer html
flutter run -d android
flutter test
flutter analyze

# Sync Server (in server/)
cd server
npm run dev:node        # Run local Node server (for Raspberry Pi / LAN testing)
npm run dev:cf          # Run Cloudflare Worker locally (wrangler)
npm run typecheck

# Deployments (Test Only)
npm run deploy:cf:test  # Deploy Cloudflare Worker & Web assets to test environment
```
