import { describe, expect, test } from "vitest";
import { incidentMatchNameToString, IncidentMatch } from "./incident.js";

describe("incidentMatchNameToString", () => {
  test("returns 'Non-Match' for undefined or null input", () => {
    expect(incidentMatchNameToString(undefined)).toBe("Non-Match");
  });

  test("returns match name for standard head-to-head matches", () => {
    const match: IncidentMatch = {
      type: "match",
      id: 123,
      division: 1,
      name: "Qualifier #12",
    };
    expect(incidentMatchNameToString(match)).toBe("Qualifier #12");
  });

  test("formats driver skills match name correctly", () => {
    const skills: IncidentMatch = {
      type: "skills",
      skillsType: "driver",
      attempt: 2,
    };
    expect(incidentMatchNameToString(skills)).toBe("Driver Skills 2");
  });

  test("formats programming / auto skills match name correctly", () => {
    const skills: IncidentMatch = {
      type: "skills",
      skillsType: "programming",
      attempt: 1,
    };
    expect(incidentMatchNameToString(skills)).toBe("Auto Skills 1");
  });
});
