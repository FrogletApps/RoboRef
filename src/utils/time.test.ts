import { describe, expect, test, vi, beforeEach, afterEach } from "vitest";
import { timeAgo, formatEventDate } from "./time.js";

describe("timeAgo", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2024-01-01T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("formats seconds ago correctly", () => {
    const input = new Date("2024-01-01T11:59:55Z"); // 5 seconds ago
    expect(timeAgo(input)).toBe("5 seconds ago");
  });

  test("formats minutes ago correctly", () => {
    const input = new Date("2024-01-01T11:55:00Z"); // 5 minutes ago
    expect(timeAgo(input)).toBe("5 minutes ago");
  });

  test("formats hours ago correctly", () => {
    const input = new Date("2024-01-01T09:00:00Z"); // 3 hours ago
    expect(timeAgo(input)).toBe("3 hours ago");
  });

  test("formats days ago correctly", () => {
    const input = new Date("2023-12-30T12:00:00Z"); // 2 days ago
    expect(timeAgo(input)).toBe("2 days ago");
  });

  test("formats weeks ago correctly", () => {
    const input = new Date("2023-12-18T12:00:00Z"); // 2 weeks ago
    expect(timeAgo(input)).toBe("2 weeks ago");
  });

  test("formats months ago correctly", () => {
    const input = new Date("2023-11-01T12:00:00Z"); // 2 months ago
    expect(timeAgo(input)).toBe("2 months ago");
  });

  test("formats years ago correctly", () => {
    const input = new Date("2022-01-01T12:00:00Z"); // 2 years ago
    expect(timeAgo(input)).toBe("2 years ago");
  });

  test("formats future time correctly", () => {
    const input = new Date("2024-01-01T12:05:00Z"); // in 5 minutes
    expect(timeAgo(input)).toBe("in 5 minutes");
  });

  test("handles exactly 0 seconds elapsed", () => {
    const input = new Date("2024-01-01T12:00:00Z"); // 0 seconds
    expect(timeAgo(input)).toBe("1 second ago");
  });

  test("formats with custom locale", () => {
    const input = new Date("2024-01-01T11:55:00Z");
    expect(timeAgo(input, "es")).toBe("hace 5 minutos");
  });
});

describe("formatEventDate", () => {
  test("returns undefined if start date is not provided", () => {
    expect(formatEventDate()).toBeUndefined();
  });

  test("returns undefined if start date is invalid", () => {
    expect(formatEventDate("invalid-date")).toBeUndefined();
  });

  test("returns formatted start date if end date is not provided", () => {
    expect(formatEventDate("2024-01-01T12:00:00", undefined, "en-US")).toMatch(/Jan 1, 2024/);
    expect(formatEventDate("2024-01-01T12:00:00", undefined, "en-GB")).toMatch(/1 Jan 2024/);
  });

  test("returns formatted start date if end date is invalid", () => {
    expect(formatEventDate("2024-01-01T12:00:00", "invalid-date", "en-US")).toMatch(/Jan 1, 2024/);
    expect(formatEventDate("2024-01-01T12:00:00", "invalid-date", "en-GB")).toMatch(/1 Jan 2024/);
  });

  test("returns formatted single day if start and end dates are the same day", () => {
    expect(formatEventDate("2024-01-01T09:00:00", "2024-01-01T17:00:00", "en-US")).toMatch(/Jan 1, 2024/);
    expect(formatEventDate("2024-01-01T09:00:00", "2024-01-01T17:00:00", "en-GB")).toMatch(/1 Jan 2024/);
  });

  test("returns formatted date range if start and end dates are different", () => {
    const usResult = formatEventDate("2024-01-01T12:00:00", "2024-01-05T12:00:00", "en-US");
    // formatRange varies slightly between platforms, but should contain the start/end dates and the year
    expect(usResult).toContain("2024");
    expect(usResult).toMatch(/Jan 1/);
    expect(usResult).toMatch(/5/);

    const gbResult = formatEventDate("2024-01-01T12:00:00", "2024-01-05T12:00:00", "en-GB");
    expect(gbResult).toContain("2024");
    expect(gbResult).toMatch(/1/);
    expect(gbResult).toMatch(/5 Jan/);
  });

  test("handles multi-day event range across different days", () => {
    const start = "2024-01-01T09:00:00";
    const end = "2024-01-03T17:00:00";
    const result = formatEventDate(start, end, "en-US");
    expect(result).toContain("2024");
    expect(result).toMatch(/Jan 1/);
    expect(result).toMatch(/3/);
  });
});
