export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    const isAssetPath =
      url.pathname.startsWith("/assets/") ||
      url.pathname.startsWith("/icons/") ||
      url.pathname.startsWith("/rules/") ||
      url.pathname.startsWith("/screenshots/") ||
      url.pathname.endsWith(".js") ||
      url.pathname.endsWith(".css") ||
      url.pathname.endsWith(".json") ||
      url.pathname.endsWith(".map") ||
      url.pathname.endsWith(".png") ||
      url.pathname.endsWith(".svg") ||
      url.pathname.endsWith(".ico") ||
      url.pathname.endsWith(".webmanifest");

    // 1. Static asset requests:
    if (isAssetPath) {
      const assetResponse = await env.ASSETS.fetch(request);
      const contentType = assetResponse.headers.get("content-type") || "";

      // If Cloudflare Pages returned HTML for a JS/CSS/asset URL, the asset does not exist!
      // Convert it to a 404 so browsers and CDNs never cache HTML as a script/module.
      if (contentType.includes("text/html") && !url.pathname.endsWith(".html")) {
        return new Response("Asset Not Found", {
          status: 404,
          headers: {
            "Content-Type": "text/plain",
            "Cache-Control": "no-cache, no-store, must-revalidate",
          },
        });
      }

      return assetResponse;
    }

    // 2. Try fetching static asset (e.g. root /)
    const response = await env.ASSETS.fetch(request);
    if (response.status !== 404) {
      return response;
    }

    // 3. For SPA client-side routes (e.g. /settings, /updates, /$sku), serve index.html
    const indexRequest = new Request(new URL("/index.html", request.url), request);
    return env.ASSETS.fetch(indexRequest);
  },
};
