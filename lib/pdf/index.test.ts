import { test, expect, describe } from "vitest";
import { extractTrailingNumber, matchComparison } from "./index.js";
import { MatchData, rounds } from "@roboref/vexevents";
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

  test("uses matchMap to order matches by round and instance when available", () => {
    const q1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "Q 1",
    };
    const r16: IncidentMatch = {
      type: "match",
      division: 1,
      id: 2,
      name: "R16 1-1",
    };
    const qf: IncidentMatch = {
      type: "match",
      division: 1,
      id: 3,
      name: "QF 1-1",
    };
    const p1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 4,
      name: "P 1",
    };

    const matchMap = new Map<number, MatchData>();
    const baseMatchData: any = { division: { id: 1 }, event: { id: 1 } };
    matchMap.set(1, { ...baseMatchData, id: 1, round: rounds.Qualification, instance: 1, matchnum: 1 });
    matchMap.set(2, { ...baseMatchData, id: 2, round: rounds.RoundOf16, instance: 1, matchnum: 1 });
    matchMap.set(3, { ...baseMatchData, id: 3, round: rounds.Quarterfinals, instance: 1, matchnum: 1 });
    matchMap.set(4, { ...baseMatchData, id: 4, round: rounds.Practice, instance: 1, matchnum: 1 });

    expect(matchComparison(p1, q1, matchMap)).toBeLessThan(0);
    expect(matchComparison(q1, r16, matchMap)).toBeLessThan(0);
    expect(matchComparison(r16, qf, matchMap)).toBeLessThan(0);
    expect(matchComparison(qf, r16, matchMap)).toBeGreaterThan(0);
  });

  test("uses matchMap to order matches by instance and matchnum within the same round", () => {
    const qf1_1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "QF 1-1",
    };
    const qf2_1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 2,
      name: "QF 2-1",
    };
    const f1_1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 3,
      name: "F 1-1",
    };
    const f1_2: IncidentMatch = {
      type: "match",
      division: 1,
      id: 4,
      name: "F 1-2",
    };

    const matchMap = new Map<number, MatchData>();
    const baseMatchData: any = { division: { id: 1 }, event: { id: 1 } };
    matchMap.set(1, { ...baseMatchData, id: 1, round: rounds.Quarterfinals, instance: 1, matchnum: 1 });
    matchMap.set(2, { ...baseMatchData, id: 2, round: rounds.Quarterfinals, instance: 2, matchnum: 1 });
    matchMap.set(3, { ...baseMatchData, id: 3, round: rounds.Finals, instance: 1, matchnum: 1 });
    matchMap.set(4, { ...baseMatchData, id: 4, round: rounds.Finals, instance: 1, matchnum: 2 });

    expect(matchComparison(qf1_1, qf2_1, matchMap)).toBeLessThan(0);
    expect(matchComparison(qf2_1, qf1_1, matchMap)).toBeGreaterThan(0);
    expect(matchComparison(f1_1, f1_2, matchMap)).toBeLessThan(0);
    expect(matchComparison(f1_2, f1_1, matchMap)).toBeGreaterThan(0);
  });

  test("handles partial matchMap presence gracefully", () => {
    const qf1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 1,
      name: "QF 1-1",
    };
    const p1: IncidentMatch = {
      type: "match",
      division: 1,
      id: 2,
      name: "P 1",
    };

    const matchMap = new Map<number, MatchData>();
    const baseMatchData: any = { division: { id: 1 }, event: { id: 1 } };
    // Only qf1 is in matchMap, p1 is not
    matchMap.set(1, { ...baseMatchData, id: 1, round: rounds.Quarterfinals, instance: 1, matchnum: 1 });

    expect(matchComparison(p1, qf1, matchMap)).toBeLessThan(0);
    expect(matchComparison(qf1, p1, matchMap)).toBeGreaterThan(0);
  });

  test("orders short match names correctly without matchMap fallback", () => {
    const p1: IncidentMatch = { type: "match", division: 1, id: 1, name: "P 1" };
    const q1: IncidentMatch = { type: "match", division: 1, id: 2, name: "Q 1" };
    const r16: IncidentMatch = { type: "match", division: 1, id: 3, name: "R16 1-1" };
    const qf: IncidentMatch = { type: "match", division: 1, id: 4, name: "QF 1-1" };
    const sf: IncidentMatch = { type: "match", division: 1, id: 5, name: "SF 1-1" };
    const f: IncidentMatch = { type: "match", division: 1, id: 6, name: "F 1-1" };

    expect(matchComparison(p1, q1)).toBeLessThan(0);
    expect(matchComparison(q1, r16)).toBeLessThan(0);
    expect(matchComparison(r16, qf)).toBeLessThan(0);
    expect(matchComparison(qf, sf)).toBeLessThan(0);
    expect(matchComparison(sf, f)).toBeLessThan(0);
  });

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
