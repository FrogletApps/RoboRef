# Security Policy

Thank you for helping keep **RoboRef** and the referees who rely on it safe. This document explains which versions are supported and how to report a security vulnerability responsibly.

## Supported Versions

RoboRef uses calendar-based versioning (`YYYY.M.D+build`). Only the **latest release** receives security fixes.

| Component | Version | Supported |
| :--- | :--- | :---: |
| Flutter client (Android, iOS, Web/PWA) | Latest release | ✅ |
| Flutter client | Older releases | ❌ |
| Cloud sync server ([roboref.app](https://roboref.app)) | Currently deployed | ✅ |
| Self-hosted LAN sync server (`server/`) | Latest `main` | ✅ |
| Self-hosted LAN sync server | Older commits | ❌ |

If you are running an older version, please update to the latest release before reporting an issue.

## Reporting a Vulnerability

> **Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.**

Report vulnerabilities privately using GitHub's **Private Vulnerability Reporting**:

1. Go to the [Security tab](https://github.com/FrogletApps/RoboRef/security) of this repository.
2. Click **Report a vulnerability**.
3. Fill in the advisory form with as much detail as possible.

Alternatively, you can email **[dev@roboref.app](mailto:dev@roboref.app)** with the subject line `Security Vulnerability Report`.

### What to include

To help us triage quickly, please include:

- A description of the vulnerability and its potential impact.
- The affected component (Flutter client, Cloudflare Worker, LAN/Node server) and version or commit.
- Step-by-step instructions to reproduce, including any proof-of-concept code, requests, or screenshots.
- Any known mitigations or suggested fixes.

## What to Expect

We will review every report on a best-effort basis and prioritise confirmed issues according to their severity. We may contact you to ask for additional information.

## Scope

### In scope

- The RoboRef Flutter client (`app/`).
- The universal sync server (`server/`), in both Cloudflare Worker and Node.js/LAN deployments.
- RoboRef-operated infrastructure at `roboref.app` and its subdomains.
- Issues such as authentication/authorisation bypass, unauthorised access to or modification of another event's or referee's data, sync protocol injection or tampering, data leakage, and remote code execution.

### Out of scope

- Vulnerabilities in third-party services or dependencies (e.g. the VEX Events API, Cloudflare, Flutter SDK) — please report these to the respective vendor. Dependency issues already tracked by Dependabot are also out of scope.
- Attacks requiring physical access to an unlocked device or a compromised operating system.
- Misconfiguration of self-hosted LAN servers that deviates from the documented setup.
- Denial-of-service attacks, volumetric testing, or spam.
- Social engineering of maintainers, event staff, or users.
- Reports from automated scanners without a demonstrated, practical impact.

## Safe Harbour

We will not pursue action against researchers who, in good faith:

- Make a reasonable effort to avoid privacy violations, data destruction, and service disruption.
- Only interact with accounts and event data they own or have explicit permission to access.
- Do not test against live tournaments or production data in a way that could disrupt an ongoing event.
- Give us reasonable time to resolve the issue before any public disclosure.

