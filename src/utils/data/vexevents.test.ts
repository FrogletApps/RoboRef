import { describe, expect, test } from "vitest";
import { isMatchElimination, ELIMINATION_ROUNDS } from "./vexevents";
import { MatchData, rounds } from "@roboref/vexevents";

const createMockMatch = (round: number): MatchData => ({
  id: 1,
  event: { id: 1, name: "Event", code: "E1" },
  division: { id: 1, name: "Division" },
  round: round,
  instance: 1,
  matchnum: 1,
  scheduled: "2024-01-01T12:00:00Z",
  started: "2024-01-01T12:00:00Z",
  field: "Field 1",
  scored: true,
  name: "Match 1",
  alliances: []
});

describe("isMatchElimination", () => {
  test("returns true for elimination rounds", () => {
    for (const round of ELIMINATION_ROUNDS) {
      expect(isMatchElimination(createMockMatch(round))).toBe(true);
    }
  });

  test("returns false for non-elimination rounds", () => {
    const nonEliminationRounds = [
      0, // None
      rounds.Practice,
      rounds.Qualification,
      rounds.TopN
    ];

    for (const round of nonEliminationRounds) {
      expect(isMatchElimination(createMockMatch(round))).toBe(false);
    }
  });
});
