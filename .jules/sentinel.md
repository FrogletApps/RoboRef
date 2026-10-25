## 2026-03-30 - Proxy Endpoint Path Traversal & Base URL Escaping
**Vulnerability:** Unsanitized `rawPath` in `/api/vexevents/*` proxy route allowed dot-segments and path manipulation in upstream URL construction.
**Learning:** `new URL(path, base)` without dot-segment filtering or `href.startsWith(base.href)` validation can allow requests to escape the intended API subpath.
**Prevention:** Always decode and sanitize path segments (stripping `.` and `..`), use trailing-slash base URLs, and enforce `url.href.startsWith(baseUrl.href)` guardrails.
