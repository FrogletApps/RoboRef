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
});

describe("formatEventDate", () => {
  test("returns undefined if start date is not provided", () => {
    expect(formatEventDate()).toBeUndefined();
  });

  test("returns undefined if start date is invalid", () => {
    expect(formatEventDate("invalid-date")).toBeUndefined();
  });

  test("returns formatted start date if end date is not provided", () => {
    expect(formatEventDate("2024-01-01")).toMatch(/Jan 1, 2024/);
  });

  test("returns formatted start date if end date is invalid", () => {
    expect(formatEventDate("2024-01-01", "invalid-date")).toMatch(/Jan 1, 2024/);
  });

  test("returns formatted single day if start and end dates are the same day", () => {
    expect(formatEventDate("2024-01-01T10:00:00Z", "2024-01-01T15:00:00Z")).toMatch(/Jan 1, 2024/);
  });

  test("returns formatted date range if start and end dates are different", () => {
    const result = formatEventDate("2024-01-01", "2024-01-05");
    // formatRange varies slightly between platforms, but should contain the start/end dates and the year
    expect(result).toContain("2024");
    expect(result).toMatch(/Jan 1/);
    expect(result).toMatch(/5/);
  });
});
