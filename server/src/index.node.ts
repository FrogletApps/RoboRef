import { serve } from "@hono/node-server";
import { createSyncApp } from "./core/app.js";
import { LocalSqliteAdapter } from "./adapters/local-sqlite.js";
import dotenv from "dotenv";

dotenv.config();

const port = parseInt(process.env.PORT || "8080", 10);
const dbPath = process.env.DB_PATH || "roboref.sqlite";

const storage = new LocalSqliteAdapter(dbPath);
await storage.init();

const app = createSyncApp(storage);

console.log(`[RoboRef Venue Server] Initialized with SQLite database: ${dbPath}`);
console.log(`[RoboRef Venue Server] Listening on http://0.0.0.0:${port}`);

serve({
  fetch: app.fetch,
  port,
});
