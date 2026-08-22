import { describe, expect, test } from "vitest";
import { ingestHex } from "./crypto.js";

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
