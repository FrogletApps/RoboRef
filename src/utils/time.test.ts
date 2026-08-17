import { describe, it, expect } from "vitest";
import { formatEventDate } from "./time";

describe("formatEventDate", () => {
  const formatter = new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  it("should return undefined if start date is not provided", () => {
    expect(formatEventDate()).toBeUndefined();
    expect(formatEventDate(undefined, "2023-01-01")).toBeUndefined();
  });

  it("should return undefined if start date is invalid", () => {
    expect(formatEventDate("invalid-date")).toBeUndefined();
  });

  it("should return formatted start date if end date is not provided", () => {
    const start = "2023-10-15T10:00:00Z";
    const expected = formatter.format(new Date(start));
    expect(formatEventDate(start)).toBe(expected);
  });

  it("should return formatted start date if end date is invalid", () => {
    const start = "2023-10-15T10:00:00Z";
    const expected = formatter.format(new Date(start));
    expect(formatEventDate(start, "invalid-date")).toBe(expected);
  });

  it("should return formatted start date if start and end dates are on the same day", () => {
    // Note: If tests run in a timezone where 10:00Z and 15:00Z fall on different days, this could fail,
    // so using local time strings is safer.
    const start = "2023-10-15T10:00:00";
    const end = "2023-10-15T15:00:00";
    const expected = formatter.format(new Date(start));
    expect(formatEventDate(start, end)).toBe(expected);
  });

  it("should return formatted date range if start and end dates are on different days", () => {
    const start = "2023-10-15T10:00:00";
    const end = "2023-10-16T15:00:00";

    let expected = "";
    try {
      expected = formatter.formatRange(new Date(start), new Date(end));
    } catch {
      expected = formatter.format(new Date(start));
    }

    expect(formatEventDate(start, end)).toBe(expected);
  });
});
