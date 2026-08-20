import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { describe, expect, test } from "vitest";
import { logicalMatchComparison, useMatchTeams } from "./vexevents.js";
import { EventData, Match, MatchData, rounds, TeamData } from "@roboref/vexevents";

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

const sampleEvent: EventData = {
  id: 10,
  sku: "RE-V5RC-24-1234",
  name: "V5RC State Championship",
  start: "2026-03-01T08:00:00Z",
  end: "2026-03-01T17:00:00Z",
  season: { id: 197, name: "2025-2026 Push Back" },
  program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
  location: { city: "Austin", region: "Texas", country: "United States" },
  divisions: [{ id: 1, name: "Division 1", order: 1 }],
};

const sampleTeams: TeamData[] = [
  {
    id: 101,
    number: "1111A",
    team_name: "Alpha Bots",
    robot_name: "Alpha",
    organization: "School A",
    location: { city: "Austin", region: "Texas", country: "United States" },
    registered: true,
    program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 102,
    number: "2222B",
    team_name: "Beta Bots",
    robot_name: "Beta",
    organization: "School B",
    location: { city: "Dallas", region: "Texas", country: "United States" },
    registered: true,
    program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 103,
    number: "3333C",
    team_name: "Gamma Bots",
    robot_name: "Gamma",
    organization: "School C",
    location: { city: "Houston", region: "Texas", country: "United States" },
    registered: true,
    program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 104,
    number: "4444D",
    team_name: "Delta Bots",
    robot_name: "Delta",
    organization: "School D",
    location: { city: "San Antonio", region: "Texas", country: "United States" },
    registered: true,
    program: { id: 1, name: "VEX V5 Robotics Competition", code: "V5RC" },
    grade: "High School",
  },
];

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

describe("useMatchTeams", () => {
  function renderUseMatchTeams(
    event?: EventData | null,
    match?: MatchData | null,
    cachedTeams?: TeamData[]
  ): TeamData[] {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: Infinity,
        },
      },
    });

    if (event && cachedTeams) {
      queryClient.setQueryData(["teams", event.sku, undefined], cachedTeams);
    }

    let hookResult: TeamData[] = [];
    function TestConsumer() {
      hookResult = useMatchTeams(event, match);
      return null;
    }

    renderToStaticMarkup(
      React.createElement(
        QueryClientProvider,
        { client: queryClient },
        React.createElement(TestConsumer, null)
      )
    );

    return hookResult;
  }

  test("returns empty array if match is null or undefined", () => {
    expect(renderUseMatchTeams(sampleEvent, null, sampleTeams)).toEqual([]);
    expect(renderUseMatchTeams(sampleEvent, undefined, sampleTeams)).toEqual([]);
  });

  test("returns empty array if event is null or undefined", () => {
    const match: MatchData = {
      ...baseData,
      alliances: [
        {
          color: "red",
          score: 0,
          teams: [{ team: { id: 101, name: "1111A", code: "1111A" }, sitting: false }],
        },
      ],
    };

    expect(renderUseMatchTeams(null, match, sampleTeams)).toEqual([]);
    expect(renderUseMatchTeams(undefined, match, sampleTeams)).toEqual([]);
  });

  test("returns empty array if event teams data is not loaded", () => {
    const match: MatchData = {
      ...baseData,
      alliances: [
        {
          color: "red",
          score: 0,
          teams: [{ team: { id: 101, name: "1111A", code: "1111A" }, sitting: false }],
        },
      ],
    };

    expect(renderUseMatchTeams(sampleEvent, match, undefined)).toEqual([]);
  });

  test("correctly maps match alliance teams to full TeamData objects in order", () => {
    const match: MatchData = {
      ...baseData,
      alliances: [
        {
          color: "red",
          score: 50,
          teams: [
            { team: { id: 101, name: "1111A", code: "1111A" }, sitting: false },
            { team: { id: 102, name: "2222B", code: "2222B" }, sitting: false },
          ],
        },
        {
          color: "blue",
          score: 45,
          teams: [
            { team: { id: 103, name: "3333C", code: "3333C" }, sitting: false },
            { team: { id: 104, name: "4444D", code: "4444D" }, sitting: false },
          ],
        },
      ],
    };

    const result = renderUseMatchTeams(sampleEvent, match, sampleTeams);

    expect(result).toHaveLength(4);
    expect(result[0]).toEqual(sampleTeams[0]);
    expect(result[1]).toEqual(sampleTeams[1]);
    expect(result[2]).toEqual(sampleTeams[2]);
    expect(result[3]).toEqual(sampleTeams[3]);
    expect(result.map((t) => t?.number)).toEqual(["1111A", "2222B", "3333C", "4444D"]);
  });

  test("handles match with single alliance or single team correctly", () => {
    const match: MatchData = {
      ...baseData,
      alliances: [
        {
          color: "blue",
          score: 20,
          teams: [{ team: { id: 102, name: "2222B", code: "2222B" }, sitting: false }],
        },
      ],
    };

    const result = renderUseMatchTeams(sampleEvent, match, sampleTeams);

    expect(result).toHaveLength(1);
    expect(result[0]).toEqual(sampleTeams[1]);
  });
});


