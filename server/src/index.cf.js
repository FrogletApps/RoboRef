import { createSyncApp } from "./core/app.js";
import { CloudflareD1Adapter } from "./adapters/cloudflare-d1.js";
let cachedApp = null;
let cachedStorage = null;
export default {
    async fetch(request, env, ctx) {
        if (!cachedStorage || !cachedApp) {
            cachedStorage = new CloudflareD1Adapter(env.DB);
            cachedApp = createSyncApp(cachedStorage);
        }
        if (env.DB) {
            try {
                await cachedStorage.init();
            }
            catch (e) {
                console.error("Failed to initialize D1 storage schema:", e);
            }
        }
        return cachedApp.fetch(request, env, ctx);
    },
};
