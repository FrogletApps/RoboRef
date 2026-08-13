import { describe, expect, test, vi } from "vitest";
import { Client } from "../main.js";

const sampleEventData = {
  id: 42000,
  sku: "RE-V5RC-24-1234",
  name: "V5RC State Championship",
  start: "2026-03-01T08:00:00Z",
  end: "2026-03-01T17:00:00Z",
  season: { id: 197, name: "2025-2026 Push Back" },
  program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
  divisions: [{ id: 1, name: "Division 1", order: 1 }],
};

describe("eventsEndpoint", () => {
  test("getBySKU returns an Event instance when SKU matches", async () => {
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          data: [sampleEventData],
          meta: { current_page: 1, last_page: 1, total: 1, next_page_url: null },
        }),
        {
          status: 200,
          headers: { "content-type": "application/json" },
        }
      )
    );

    const client = Client({
      authorization: { token: "test-token" },
      request: { fetch: mockFetch },
    });

    const result = await client.events.getBySKU("RE-V5RC-24-1234");
    expect(result.data).toBeDefined();
    expect(result.data?.sku).toBe("RE-V5RC-24-1234");
    expect(result.data?.name).toBe("V5RC State Championship");
  });

  test("getBySKU returns null if SKU is not found", async () => {
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          data: [],
          meta: { current_page: 1, last_page: 1, total: 0, next_page_url: null },
        }),
        {
          status: 200,
          headers: { "content-type": "application/json" },
        }
      )
    );

    const client = Client({
      authorization: { token: "test-token" },
      request: { fetch: mockFetch },
    });

    const result = await client.events.getBySKU("RE-NONEXISTENT");
    expect(result.data).toBeNull();
  });

  test("get returns event by numeric ID", async () => {
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(JSON.stringify(sampleEventData), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );

    const client = Client({
      authorization: { token: "test-token" },
      request: { fetch: mockFetch },
    });

    const result = await client.events.get(42000);
    expect(result.data?.id).toBe(42000);
    expect(result.data?.name).toBe("V5RC State Championship");
  });

  test("search accumulates multiple pages via PaginatedGET", async () => {
    let callCount = 0;
    const mockFetch = vi.fn().mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        return new Response(
          JSON.stringify({
            data: [{ ...sampleEventData, id: 101, sku: "SKU-PAGE-1" }],
            meta: {
              current_page: 1,
              last_page: 2,
              total: 2,
              next_page_url: "https://events.vex.com/api/v2/events?page=2",
            },
          }),
          {
            status: 200,
            headers: { "content-type": "application/json" },
          }
        );
      }
      return new Response(
        JSON.stringify({
          data: [{ ...sampleEventData, id: 102, sku: "SKU-PAGE-2" }],
          meta: {
            current_page: 2,
            last_page: 2,
            total: 2,
            next_page_url: null,
          },
        }),
        {
          status: 200,
          headers: { "content-type": "application/json" },
        }
      );
    });

    const client = Client({
      authorization: { token: "test-token" },
      request: { fetch: mockFetch },
    });

    const result = await client.events.search({ name: "Championship" });
    expect(result.data).toHaveLength(2);
    expect(result.data?.[0].sku).toBe("SKU-PAGE-1");
    expect(result.data?.[1].sku).toBe("SKU-PAGE-2");
    expect(callCount).toBe(2);
  });

  test("bubbles network or HTTP errors cleanly without crashing", async () => {
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ message: "Internal server error" }), {
        status: 500,
        headers: { "content-type": "application/json" },
      })
    );

    const client = Client({
      authorization: { token: "test-token" },
      request: { fetch: mockFetch },
    });

    const result = await client.events.getBySKU("RE-V5RC-ERROR");
    expect(result.error).toBeDefined();
    expect(result.data).toBeUndefined();
  });
});
