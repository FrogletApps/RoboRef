import { describe, expect, test } from "vitest";
import { logicalMatchComparison } from "./vexevents.js";
import { Match, MatchData, rounds } from "@roboref/vexevents";

const baseData: MatchData = {
  id: 1,
  event: { id: 10, name: "Event" },
  division: { id: 1, name: "Division" },
  round: rounds.Qualification,
  instance: 1,
  matchnum: 1,
  scored: true,
  name: "Match",
  alliances: [],
};

describe("logicalMatchComparison", () => {
  test("orders rounds in correct tournament progression order", () => {
    const p = { ...baseData, round: rounds.Practice, matchnum: 1 };
    const q = { ...baseData, round: rounds.Qualification, matchnum: 1 };
    const rr = { ...baseData, round: rounds.RoundRobin, matchnum: 1 };
    const r16 = { ...baseData, round: rounds.RoundOf16, matchnum: 1 };
    const qf = { ...baseData, round: rounds.Quarterfinals, matchnum: 1 };
    const sf = { ...baseData, round: rounds.Semifinals, matchnum: 1 };
    const f = { ...baseData, round: rounds.Finals, matchnum: 1 };
    const topN = { ...baseData, round: rounds.TopN, matchnum: 1 };

    expect(logicalMatchComparison(p, q)).toBeLessThan(0);
    expect(logicalMatchComparison(q, rr)).toBeLessThan(0);
    expect(logicalMatchComparison(rr, r16)).toBeLessThan(0);
    expect(logicalMatchComparison(r16, qf)).toBeLessThan(0);
    expect(logicalMatchComparison(qf, sf)).toBeLessThan(0);
    expect(logicalMatchComparison(sf, f)).toBeLessThan(0);
    expect(logicalMatchComparison(f, topN)).toBeLessThan(0);
  });

  test("orders matches numerically by instance and matchnum", () => {
    const q1 = { ...baseData, round: rounds.Qualification, matchnum: 1 };
    const q2 = { ...baseData, round: rounds.Qualification, matchnum: 2 };
    const q10 = { ...baseData, round: rounds.Qualification, matchnum: 10 };

    expect(logicalMatchComparison(q1, q2)).toBeLessThan(0);
    expect(logicalMatchComparison(q2, q10)).toBeLessThan(0);

    const qf1_1 = { ...baseData, round: rounds.Quarterfinals, instance: 1, matchnum: 1 };
    const qf2_1 = { ...baseData, round: rounds.Quarterfinals, instance: 2, matchnum: 1 };

    expect(logicalMatchComparison(qf1_1, qf2_1)).toBeLessThan(0);
  });

  test("uses scheduled timestamp as a tie-breaker for identical match numbers", () => {
    const early = {
      ...baseData,
      round: rounds.Qualification,
      matchnum: 1,
      scheduled: "2026-08-15T09:00:00Z",
    };
    const late = {
      ...baseData,
      round: rounds.Qualification,
      matchnum: 1,
      scheduled: "2026-08-15T14:00:00Z",
    };

    expect(logicalMatchComparison(early, late)).toBeLessThan(0);
    expect(logicalMatchComparison(late, early)).toBeGreaterThan(0);
  });
});

describe("Match persistence serialization / deserialization", () => {
  test("reconstitutes Match models with functional methods from plain data", () => {
    const rawData: MatchData = {
      ...baseData,
      alliances: [
        {
          color: "blue",
          score: 10,
          teams: [{ team: { id: 1, name: "1111A", code: "1111A" }, sitting: false }],
        },
        {
          color: "red",
          score: 20,
          teams: [{ team: { id: 2, name: "2222B", code: "2222B" }, sitting: false }],
        },
      ],
    };

    const matchInstance = new Match(rawData);
    const serialized = matchInstance.getData();

    // Deserialization check:
    const rehydrated = new Match(serialized);
    expect(rehydrated.alliance("red").score).toBe(20);
    expect(rehydrated.allianceOutcome().winner?.color).toBe("red");
    expect(rehydrated.teamOutcome("2222B")).toBe("win");
  });
});
