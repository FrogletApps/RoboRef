import { describe, expect, test } from "vitest";
import { filterTeams } from "./filterteams.js";
import { TeamData } from "@roboref/vexevents";

const mockTeams: TeamData[] = [
  {
    id: 1,
    number: "229V",
    team_name: "Clarkson Robotics",
    robot_name: "Knight",
    organization: "Clarkson University",
    location: {
      city: "Potsdam",
      region: "New York",
      postcode: "13699",
      country: "United States",
    },
    registered: true,
    program: { id: 1, name: "V5RC", code: "V5RC" },
    grade: "College",
  },
  {
    id: 2,
    number: "3796B",
    team_name: "Froglet Robotics",
    robot_name: "Ribbit",
    organization: "Froglet Academy",
    location: {
      city: "London",
      region: "England",
      postcode: "SW1A",
      country: "United Kingdom",
    },
    registered: true,
    program: { id: 1, name: "V5RC", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 3,
    number: "99999A",
    team_name: "Alpha Bots",
    robot_name: "Prime",
    organization: "Tech High School",
    location: {
      city: "Austin",
      region: "Texas",
      postcode: "78701",
      country: "United States",
    },
    registered: true,
    program: { id: 1, name: "V5RC", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 4,
    number: "3850Z",
    team_name: "The Gilberd School",
    robot_name: "Wheatley",
    organization: "The Gilberd School",
    location: {
      city: "Colchester",
      region: "England",
      postcode: "CO4 9PU",
      country: "United Kingdom",
    },
    registered: true,
    program: { id: 1, name: "V5RC", code: "V5RC" },
    grade: "High School",
  },
  {
    id: 5,
    number: "81710A",
    team_name: "Team Camulodunum",
    robot_name: "Robot",
    organization: "Team Camulodunum",
    location: {
      city: "Colchester",
      region: "England",
      postcode: "CO1 1AA",
      country: "United Kingdom",
    },
    registered: true,
    program: { id: 1, name: "V5RC", code: "V5RC" },
    grade: "High School",
  },
];

describe("filterTeams", () => {
  test("returns all teams when filter is null, undefined, or whitespace", () => {
    expect(filterTeams(mockTeams, null)).toEqual(mockTeams);
    expect(filterTeams(mockTeams, "")).toEqual(mockTeams);
    expect(filterTeams(mockTeams, "   ")).toEqual(mockTeams);
  });

  test("filters by team number case-insensitively", () => {
    const result = filterTeams(mockTeams, "229v");
    expect(result).toHaveLength(1);
    expect(result[0].number).toBe("229V");

    const result3850 = filterTeams(mockTeams, "3850z");
    expect(result3850).toHaveLength(1);
    expect(result3850[0].number).toBe("3850Z");

    const result81710 = filterTeams(mockTeams, "81710a");
    expect(result81710).toHaveLength(1);
    expect(result81710[0].number).toBe("81710A");
  });

  test("filters by team name", () => {
    const result = filterTeams(mockTeams, "Froglet");
    expect(result).toHaveLength(1);
    expect(result[0].number).toBe("3796B");

    const resultCamulodunum = filterTeams(mockTeams, "Camulodunum");
    expect(resultCamulodunum).toHaveLength(1);
    expect(resultCamulodunum[0].number).toBe("81710A");
  });

  test("filters by organization", () => {
    const result = filterTeams(mockTeams, "Clarkson");
    expect(result).toHaveLength(1);
    expect(result[0].number).toBe("229V");

    const resultGilberd = filterTeams(mockTeams, "Gilberd");
    expect(resultGilberd).toHaveLength(1);
    expect(resultGilberd[0].number).toBe("3850Z");
  });

  test("handles special characters and spaces gracefully via normalized matching", () => {
    const result = filterTeams(mockTeams, "229-V");
    expect(result).toHaveLength(1);
    expect(result[0].number).toBe("229V");

    const resultNorm = filterTeams(mockTeams, "3850 Z");
    expect(resultNorm).toHaveLength(1);
    expect(resultNorm[0].number).toBe("3850Z");
  });

  test("matches teams present in matchTeamNumbers set", () => {
    const matchNumbers = new Set(["99999A", "3850Z"]);
    const result = filterTeams(mockTeams, "SOMETHING_ELSE", matchNumbers);
    expect(result.some((t) => t.number === "99999A")).toBe(true);
    expect(result.some((t) => t.number === "3850Z")).toBe(true);
  });

  test("returns empty array when no team matches", () => {
    const result = filterTeams(mockTeams, "NONEXISTENT_TEAM");
    expect(result).toEqual([]);
  });
});
