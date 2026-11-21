import { describe, it } from "node:test";
import assert from "node:assert";
import { createWebWorker } from "./index.ts";

describe("RoboRef Web Worker (/privacy & Static Assets)", () => {
  it("serves responsive HTML from Cloudflare ASSETS binding", async () => {
    const worker = createWebWorker();
    const mockMarkdown = "# RoboRef Privacy Policy\n\n- No tracking\n";

    const res = await worker.fetch(new Request("https://roboref.app/privacy"), {
      ASSETS: {
        fetch: async (input: RequestInfo | URL) => {
          const reqUrl = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
          assert.match(reqUrl, /\/assets\/assets\/privacy\.md$/);
          return new Response(mockMarkdown, { status: 200 });
        },
      },
    });

    assert.strictEqual(res.status, 200);
    assert.match(res.headers.get("Content-Type") || "", /text\/html/);
    const html = await res.text();
    assert.match(html, /RoboRef Privacy Policy/);
    assert.match(html, /<li>No tracking<\/li>/);
  });

  it("serves raw markdown when requested via Accept header", async () => {
    const worker = createWebWorker();
    const mockMarkdown = "# RoboRef Privacy Policy\n\nRaw content";

    const res = await worker.fetch(
      new Request("https://roboref.app/privacy/", {
        headers: { Accept: "text/markdown" },
      }),
      {
        ASSETS: {
          fetch: async () => new Response(mockMarkdown, { status: 200 }),
        },
      }
    );

    assert.strictEqual(res.status, 200);
    assert.match(res.headers.get("Content-Type") || "", /text\/markdown/);
    assert.strictEqual(await res.text(), mockMarkdown);
  });

  it("returns 503 when ASSETS fails to load privacy.md", async () => {
    const worker = createWebWorker();
    const originalError = console.error;
    console.error = () => {};

    try {
      const res = await worker.fetch(new Request("https://roboref.app/privacy"), {
        ASSETS: {
          fetch: async () => {
            throw new Error("ASSETS unavailable");
          },
        },
      });

      assert.strictEqual(res.status, 503);
      assert.strictEqual(await res.text(), "Privacy policy is temporarily unavailable.");
    } finally {
      console.error = originalError;
    }
  });

  it("delegates non-privacy routes to ASSETS", async () => {
    const worker = createWebWorker();
    let forwardedUrl = "";

    const res = await worker.fetch(new Request("https://roboref.app/manifest.json"), {
      ASSETS: {
        fetch: async (input: RequestInfo | URL) => {
          forwardedUrl = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
          return new Response('{"name":"RoboRef"}', { status: 200 });
        },
      },
    });

    assert.strictEqual(res.status, 200);
    assert.strictEqual(forwardedUrl, "https://roboref.app/manifest.json");
  });
});
