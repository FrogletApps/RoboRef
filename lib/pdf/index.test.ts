import { test, expect, describe } from "vitest";
import { extractTrailingNumber, matchComparison } from "./index.js";
import { IncidentMatch } from "@roboref/share";

describe("extractTrailingNumber", () => {
  test("extracts single and multi-digit trailing numbers", () => {
    expect(extractTrailingNumber("Qualifier 1")).toBe(1);
    expect(extractTrailingNumber("Qualifier 12")).toBe(12);
    expect(extractTrailingNumber("Practice 105")).toBe(105);
    expect(extractTrailingNumber("Finals 1-2")).toBe(2);
  });

  test("returns 0 for non-numeric or empty strings", () => {
    expect(extractTrailingNumber("")).toBe(0);
    expect(extractTrailingNumber("Match")).toBe(0);
    expect(extractTrailingNumber("Qualifier ")).toBe(0);
  });

  test("handles pure number strings", () => {
    expect(extractTrailingNumber("0")).toBe(0);
    expect(extractTrailingNumber("42")).toBe(42);
  });

  test("is immune to ReDoS on REALLY long inputs", () => {
    const longString = "Qualifier " + "0".repeat(200_000);
    const start = performance.now();
    const result = extractTrailingNumber(longString);
    const elapsed = performance.now() - start;

    expect(result).toBe(0);
    expect(elapsed).toBeLessThan(50); // should complete in < 5ms in practice
  });
});

describe("matchComparison", () => {
  test("handles undefined matches", () => {
    const matchA: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "Qualifier 1",
    };
    expect(matchComparison(undefined, undefined)).toBe(0);
    expect(matchComparison(undefined, matchA)).toBe(-1);
    expect(matchComparison(matchA, undefined)).toBe(1);
  });

  test("orders skills vs match correctly", () => {
    const match: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "Qualifier 1",
    };
    const skills: IncidentMatch = {
      type: "skills",
      attempt: 1,
      skillsType: "driver",
    };
    expect(matchComparison(match, skills)).toBe(-1);
    expect(matchComparison(skills, match)).toBe(1);
  });

  test("orders matches by division, round, and instance number", () => {
    const q1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "Qualifier 1",
    };
    const q2: IncidentMatch = {
      type: "match",
      division: 1,
      id: 2,
      name: "Qualifier 2",
    };
    const q10: IncidentMatch = {
      type: "match",
      division: 1,
      id: 10,
      name: "Qualifier 10",
    };
    const p1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 100,
      name: "Practice 1",
    };

    expect(matchComparison(p1, q1)).toBeLessThan(0); // Practice before Qualifier
    expect(matchComparison(q1, q2)).toBeLessThan(0); // Q1 before Q2
    expect(matchComparison(q2, q10)).toBeLessThan(0); // Q2 before Q10 (numeric sort, not lexicographic)
    expect(matchComparison(q10, q2)).toBeGreaterThan(0);
  });

  test("handles ReDoS attack vectors gracefully in match comparison", () => {
    const evilMatchA: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "Qualifier " + "0".repeat(100_000) + "1",
    };
    const evilMatchB: IncidentMatch = {
      type: "match",
      division: 1,
      id: 2,
      name: "Qualifier " + "0".repeat(100_000) + "2",
    };

    const start = performance.now();
    const result = matchComparison(evilMatchA, evilMatchB);
    const elapsed = performance.now() - start;

    expect(result).toBeLessThan(0);
    expect(elapsed).toBeLessThan(50);
  });
});
