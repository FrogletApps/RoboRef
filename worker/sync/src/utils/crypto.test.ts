import { describe, expect, test, vi, afterEach } from "vitest";
import { ingestHex, importKey, KEY_PREFIX } from "./crypto.js";

describe("ingestHex", () => {
  test("parses valid hex strings into Uint8Array", () => {
    const hex = "deadbeef";
    const result = ingestHex(hex);
    expect(result).toBeInstanceOf(Uint8Array);
    expect(result).toEqual(new Uint8Array([0xde, 0xad, 0xbe, 0xef]));
  });

  test("returns empty Uint8Array for empty string", () => {
    const hex = "";
    const result = ingestHex(hex);
    expect(result).toBeInstanceOf(Uint8Array);
    expect(result).toEqual(new Uint8Array([]));
  });

  test("parses valid hex string with leading zeros", () => {
    const hex = "001122";
    const result = ingestHex(hex);
    expect(result).toBeInstanceOf(Uint8Array);
    expect(result).toEqual(new Uint8Array([0x00, 0x11, 0x22]));
  });

  test("returns null for invalid hex strings", () => {
    const hex = "xyzq";
    const result = ingestHex(hex);
    expect(result).toBeNull();
  });

  test("returns null for partially invalid hex strings", () => {
    const hex = "deagbeef"; // 'g' is invalid
    const result = ingestHex(hex);
    expect(result).toBeNull();
  });
});

describe("importKey", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  test("returns null if hexKey does not start with KEY_PREFIX", async () => {
    const result = await importKey("INVALID:deadbeef");
    expect(result).toBeNull();
  });

  test("returns null if ingestHex fails", async () => {
    const result = await importKey(`${KEY_PREFIX}invalidhex`);
    expect(result).toBeNull();
  });

  test("returns null if crypto.subtle.importKey throws an error", async () => {
    vi.stubGlobal("crypto", {
      subtle: {
        importKey: vi.fn().mockRejectedValue(new Error("Import failed")),
      },
    });

    const result = await importKey(`${KEY_PREFIX}deadbeef`);
    expect(result).toBeNull();
  });

  test("returns CryptoKey on successful import", async () => {
    const mockKey = {} as CryptoKey;
    vi.stubGlobal("crypto", {
      subtle: {
        importKey: vi.fn().mockResolvedValue(mockKey),
      },
    });

    const result = await importKey(`${KEY_PREFIX}deadbeef`);
    expect(result).toBe(mockKey);
  });
});
