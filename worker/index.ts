import { renderPrivacyHtml } from "./privacy.ts";

export interface Env {
  ENVIRONMENT?: string;
  ASSETS?: { fetch: typeof fetch };
}

export function createWebWorker() {
  let cachedPrivacyMarkdown: string | null = null;

  return {
    async fetch(request: Request, env: Env): Promise<Response> {
      const url = new URL(request.url);

      if ((request.method === "GET" || request.method === "HEAD") &&
          (url.pathname === "/privacy" || url.pathname === "/privacy/")) {
        let markdown = cachedPrivacyMarkdown;

        if (!markdown && env?.ASSETS) {
          try {
            const assetUrl = new URL("/assets/assets/privacy.md", request.url);
            const res = await env.ASSETS.fetch(new Request(assetUrl));
            if (res.ok) {
              markdown = await res.text();
              cachedPrivacyMarkdown = markdown;
            }
          } catch (err) {
            console.error("Failed to fetch privacy markdown from ASSETS:", err);
          }
        }

        if (!markdown) {
          return new Response("Privacy policy is temporarily unavailable.", {
            status: 503,
            headers: { "Content-Type": "text/plain; charset=utf-8" },
          });
        }

        const accept = request.headers.get("Accept") || "";
        if (accept.includes("text/markdown") || accept.includes("text/plain")) {
          return new Response(markdown, {
            status: 200,
            headers: {
              "Content-Type": accept.includes("text/markdown")
                ? "text/markdown; charset=utf-8"
                : "text/plain; charset=utf-8",
            },
          });
        }

        return new Response(renderPrivacyHtml(markdown), {
          status: 200,
          headers: {
            "Content-Type": "text/html; charset=utf-8",
            "Cache-Control": "public, max-age=0, must-revalidate",
          },
        });
      }

      if (env?.ASSETS) {
        return env.ASSETS.fetch(request);
      }

      return new Response("Not Found", { status: 404 });
    },
  };
}

export default createWebWorker();
