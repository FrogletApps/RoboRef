import { describe, expect, test } from "vitest";
import { Match } from "./Match.js";
import { MatchData, rounds } from "../types.js";

const baseMatchData: MatchData = {
  id: 1001,
  event: { id: 1, name: "Test Championship", code: "RE-V5RC-24-0001" },
  division: { id: 1, name: "Division 1" },
  round: rounds.Qualification,
  instance: 1,
  matchnum: 15,
  scheduled: "2026-08-15T10:00:00Z",
  started: "2026-08-15T10:02:00Z",
  field: "Field 1",
  scored: true,
  name: "Qualifier #15",
  alliances: [
    {
      color: "blue",
      score: 24,
      teams: [
        { team: { id: 101, name: "1111A", code: "1111A" }, sitting: false },
        { team: { id: 102, name: "2222B", code: "2222B" }, sitting: false },
      ],
    },
    {
      color: "red",
      score: 36,
      teams: [
        { team: { id: 103, name: "3333C", code: "3333C" }, sitting: false },
        { team: { id: 104, name: "4444D", code: "4444D" }, sitting: true }, // sitting team
      ],
    },
  ],
};

describe("Match wrapper", () => {
  test("orders alliances with red first", () => {
    const match = new Match(baseMatchData);
    expect(match.alliances[0].color).toBe("red");
    expect(match.alliances[1].color).toBe("blue");
  });

  test("retrieves alliance by color", () => {
    const match = new Match(baseMatchData);
    const red = match.alliance("red");
    const blue = match.alliance("blue");

    expect(red.score).toBe(36);
    expect(blue.score).toBe(24);
  });

  test("calculates allianceOutcome for red win, blue win, and ties", () => {
    const redWinMatch = new Match(baseMatchData);
    expect(redWinMatch.allianceOutcome().winner?.color).toBe("red");
    expect(redWinMatch.allianceOutcome().loser?.color).toBe("blue");

    const blueWinData: MatchData = {
      ...baseMatchData,
      alliances: [
        { ...baseMatchData.alliances[0], score: 50 },
        { ...baseMatchData.alliances[1], score: 20 },
      ],
    };
    const blueWinMatch = new Match(blueWinData);
    expect(blueWinMatch.allianceOutcome().winner?.color).toBe("blue");
    expect(blueWinMatch.allianceOutcome().loser?.color).toBe("red");

    const tieData: MatchData = {
      ...baseMatchData,
      alliances: [
        { ...baseMatchData.alliances[0], score: 30 },
        { ...baseMatchData.alliances[1], score: 30 },
      ],
    };
    const tieMatch = new Match(tieData);
    expect(tieMatch.allianceOutcome().winner).toBeNull();
    expect(tieMatch.allianceOutcome().loser).toBeNull();
  });

  test("calculates teamOutcome correctly", () => {
    const match = new Match(baseMatchData);
    expect(match.teamOutcome("3333C")).toBe("win");
    expect(match.teamOutcome("1111A")).toBe("loss");

    const unscoredMatch = new Match({
      ...baseMatchData,
      scored: false,
      alliances: [
        { ...baseMatchData.alliances[0], score: 0 },
        { ...baseMatchData.alliances[1], score: 0 },
      ],
    });
    expect(unscoredMatch.teamOutcome("3333C")).toBe("unscored");

    const tieMatch = new Match({
      ...baseMatchData,
      scored: true,
      alliances: [
        { ...baseMatchData.alliances[0], score: 30 },
        { ...baseMatchData.alliances[1], score: 30 },
      ],
    });
    expect(tieMatch.teamOutcome("3333C")).toBe("tie");
  });

  test("filters out sitting teams from teams()", () => {
    const match = new Match(baseMatchData);
    const activeTeams = match.teams();

    expect(activeTeams.map((t) => t.name)).toEqual(["3333C", "1111A", "2222B"]);
    expect(activeTeams.some((t) => t.name === "4444D")).toBe(false);
  });

  test("formats shortName for all competition rounds", () => {
    const makeMatch = (round: number, instance = 1, matchnum = 1) =>
      new Match({ ...baseMatchData, round, instance, matchnum });

    expect(makeMatch(rounds.Practice, 1, 5).shortName()).toBe("P 5");
    expect(makeMatch(rounds.Qualification, 1, 42).shortName()).toBe("Q 42");
    expect(makeMatch(rounds.RoundOf16, 2, 1).shortName()).toBe("R16 2-1");
    expect(makeMatch(rounds.Quarterfinals, 3, 2).shortName()).toBe("QF 3-2");
    expect(makeMatch(rounds.Semifinals, 1, 1).shortName()).toBe("SF 1-1");
    expect(makeMatch(rounds.Finals, 1, 3).shortName()).toBe("F 1-3");
    expect(makeMatch(rounds.RoundRobin, 2, 2).shortName()).toBe("RR 2-2");
    expect(makeMatch(rounds.TopN, 1, 4).shortName()).toBe("F 4");
  });

  test("serializes and deserializes accurately with getData and toJSON", () => {
    const match = new Match(baseMatchData);
    const data = match.getData();

    expect(data.id).toBe(1001);
    expect(data.alliances[0].color).toBe("red");
    expect(match.toJSON()).toEqual(data);
  });
});
