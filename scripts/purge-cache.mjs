#!/usr/bin/env node

/**
 * Purge Cloudflare CDN cache after a Pages deployment.
 *
 * Prevents stale responses from being served — specifically the dangerous case
 * where a deploy race condition causes Cloudflare's SPA `_redirects` fallback
 * to return index.html for /assets/* URLs, which then gets cached immutably by
 * the CDN as `text/html` instead of `application/javascript`.
 *
 * Required environment variables:
 *   CF_ZONE_ID              – Cloudflare Zone ID for roboref.fyi
 *   CLOUDFLARE_API_TOKEN    – API token with Zone.Cache Purge permission
 *
 * Usage:
 *   node scripts/purge-cache.mjs
 */

// Load .env.local if it exists (Node doesn't do this automatically like Vite)
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
try {
  const envPath = resolve(import.meta.dirname, "..", ".env.local");
  for (const line of readFileSync(envPath, "utf-8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const val = trimmed.slice(eq + 1).trim();
    if (!process.env[key]) process.env[key] = val;
  }
} catch {}

const zoneId = process.env.CF_ZONE_ID;
const apiToken = process.env.CLOUDFLARE_API_TOKEN;

if (!zoneId || !apiToken) {
  const missing = [
    !zoneId && "CF_ZONE_ID",
    !apiToken && "CLOUDFLARE_API_TOKEN",
  ].filter(Boolean);
  console.warn(
    `⚠️  Skipping cache purge: ${missing.join(" and ")} not set.\n` +
      `   Set these in your environment or .env.local to enable automatic cache purging after deploys.`
  );
  process.exit(0);
}

async function purgeCache() {
  const url = `https://api.cloudflare.com/client/v4/zones/${zoneId}/purge_cache`;

  console.log("🔄 Purging Cloudflare CDN cache…");

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ purge_everything: true }),
  });

  const data = await res.json();

  if (data.success) {
    console.log("✅ CDN cache purged successfully.");
  } else {
    console.error("❌ Cache purge failed:", JSON.stringify(data.errors, null, 2));
    process.exit(1);
  }
}

purgeCache();
