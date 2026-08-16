#!/usr/bin/env node

/**
 * Purge Cloudflare CDN cache after a Pages deployment.
 *
 * Prevents stale responses from being served — specifically the dangerous case
 * where a deploy race condition causes Cloudflare's SPA fallback to serve
 * old index.html or stale assets.
 *
 * Required environment variables:
 *   CF_ZONE_ID      – Cloudflare Zone ID for roboref.fyi
 *   CF_PURGE_TOKEN   – API token with Zone.Cache Purge permission
 *
 * Usage:
 *   node scripts/purge-cache.mjs
 */

import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

function loadEnvFile(filename) {
  try {
    const envPath = resolve(import.meta.dirname, "..", filename);
    if (!existsSync(envPath)) return;
    for (const line of readFileSync(envPath, "utf-8").split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eq = trimmed.indexOf("=");
      if (eq === -1) continue;
      const key = trimmed.slice(0, eq).trim();
      let val = trimmed.slice(eq + 1).trim();
      val = val.replace(/^["']|["']$/g, "").trim();
      if (!process.env[key] || process.env[key] === "") {
        process.env[key] = val;
      }
    }
  } catch {}
}

loadEnvFile(".env");
loadEnvFile(".env.local");

const zoneId = process.env.CF_ZONE_ID;
const apiToken = process.env.CF_PURGE_TOKEN;

if (!zoneId || !apiToken) {
  const missing = [
    !zoneId && "CF_ZONE_ID",
    !apiToken && "CF_PURGE_TOKEN",
  ].filter(Boolean);
  console.warn(
    `⚠️  Skipping cache purge: ${missing.join(" and ")} not set.\n` +
      `   Set these in your environment or .env.local to enable automatic cache purging after deploys.`
  );
  process.exit(0);
}

async function purgeCache() {
  // Give Cloudflare Pages 2.5 seconds to settle its global deployment routing
  // across edge nodes before triggering the cache purge.
  console.log("⏳ Waiting 2.5s for Cloudflare edge routing to settle…");
  await new Promise((resolve) => setTimeout(resolve, 2500));

  const url = `https://api.cloudflare.com/client/v4/zones/${zoneId}/purge_cache`;

  console.log("🔄 Purging Cloudflare CDN cache…");

  try {
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
  } catch (err) {
    console.error("❌ Cache purge request failed:", err);
    process.exit(1);
  }
}

purgeCache();
