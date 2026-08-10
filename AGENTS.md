# RoboRef AI Agent Guidelines & Context (`AGENTS.md`)

Welcome! This file (`AGENTS.md`) is the primary guidelines and context document for AI coding agents (Antigravity, Gemini, Claude, Cursor, Copilot, etc.) working on the RoboRef codebase.

---

## 1. Project Overview

**RoboRef** ([roboref.fyi](https://roboref.fyi)) is an offline-first Progressive Web App (PWA) anomaly log for Head Referees at VEX Robotics competition tournaments. It allows referees to quickly log incidents, view team summary histories, and automatically synchronize notes across devices.

### Tech Stack & Architecture
- **Frontend**: React 19, TypeScript, Vite, Tailwind CSS, TanStack Router, TanStack Query, Motion.
- **Offline Storage**: IndexedDB via `idb-keyval`, local persistence via `@tanstack/react-query-persist-client`.
- **Sync Worker**: Cloudflare Workers & Durable Objects (`worker/sync`).
- **Shared Libraries**: `lib/vexevents`, `lib/share`, `lib/consistency`, `lib/pdf`.

---

## 2. Crucial Guidelines for AI Agents

When assisting with code modifications or feature implementations, AI agents **MUST** follow these core guidelines:

### A. User-Facing Changes & Change Log
- **Changelog Requirement**: Whenever making a change that affects the end user (UI modifications, new features, bug fixes impacting user interaction, UX improvements), you **MUST** add an entry to `documents/changeLog.md` under a heading with the current date (formatted as `## DD Month YYYY`, e.g. `## 31 July 2026`).

### B. Page Heading & File Name Consistency
- **File Renaming**: When a page heading or navigation label changes, offer or ensure renaming the corresponding route and component files in `src/routes/` or `src/components/` so that internal filenames remain consistent with user-facing page headings.

### C. Offline-First & Low-Bandwidth Constraints
- RoboRef is designed for mobile devices in event venues with poor or non-existent internet connectivity.
- All user actions must function offline and gracefully reconcile when connectivity returns.
- Keep the total PWA application bundle size under **5 MB**.

### D. Touch-Friendly & Mobile-First UI
- Prioritize touch-friendly, small-screen mobile layouts over desktop layouts.
- Ensure high contrast, clear visual feedback, and fast user workflows for referees on the field.

### E. Commit Messages & GitHub Issue References
- **Summarize Changes**: Write clear, descriptive git commit messages/notes that summarize the exact modifications made.
- **GitHub Issue Linking**: When working on or fixing a GitHub issue, always include the issue reference (e.g. `Fixes #54` or `Resolves #54`) in the commit message so the commit links directly to the issue.

---

## 3. Key Development Commands

```bash
# Start local development server (frontend + shared libraries)
npm run dev

# Type check codebase
npx tsc --noEmit

# Build production bundle
npm run frontend:build

# Run local Cloudflare Worker sync server
npm run worker:dev

# Run linter
npm run lint
```
