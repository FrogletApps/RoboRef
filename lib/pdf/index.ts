import { CellConfig, jsPDF } from "jspdf";
import {
  Incident,
  IncidentMatch,
  incidentMatchNameToString,
  User,
} from "@roboref/share";
import { VexEventsClient, MatchData, rounds } from "@roboref/vexevents";

export type GenerateIncidentReportPDFOptions = {
  sku: string;
  users: User[];
  client: VexEventsClient;
  incidents: Incident[];
  formatters: {
    date: Intl.DateTimeFormat;
  };
};

type IncidentRow = {
  team: string;
  match: string;
  rule: string;
  contact: string;
  notes: string;
};

export function teamComparison(a: string, b: string): number {
  const baseA = a.slice(0, -1);
  const baseB = b.slice(0, -1);

  if (baseA !== baseB) {
    const numA = parseInt(baseA);
    const numB = parseInt(baseB);

    if (isNaN(numA) || isNaN(numB)) {
      return baseA.localeCompare(baseB);
    }

    if (numA < numB) {
      return -1;
    } else if (numA > numB) {
      return 1;
    }
  }

  const letterA = a.slice(-1);
  const letterB = b.slice(-1);

  if (letterA !== letterB) {
    return letterA.localeCompare(letterB);
  }

  return 0;
}


const ROUND_ORDER: Record<number, number> = {
  [rounds.Practice]: 1,
  [rounds.Qualification]: 2,
  [rounds.RoundOf16]: 3,
  [rounds.Quarterfinals]: 4,
  [rounds.Semifinals]: 5,
  [rounds.Finals]: 6,
  [rounds.TopN]: 7,
  [rounds.RoundRobin]: 8,
};

const getRoundOrder = (round: number) => ROUND_ORDER[round] ?? 99;

function getMatchRoundOrder(
  match: IncidentMatch,
  matchData?: MatchData
): number {
  if (matchData) {
    return getRoundOrder(matchData.round);
  }

  const upper = match.name.toUpperCase().trim();
  if (
    upper.startsWith("P ") ||
    upper.startsWith("P#") ||
    upper.startsWith("P_") ||
    upper.includes("PRACTICE")
  ) {
    return 1;
  }
  if (
    upper.startsWith("Q ") ||
    upper.startsWith("Q#") ||
    upper.startsWith("Q_") ||
    upper.includes("QUAL")
  ) {
    return 2;
  }
  if (upper.startsWith("R16") || upper.includes("ROUND OF 16")) {
    return 3;
  }
  if (upper.startsWith("QF") || upper.includes("QUARTER")) {
    return 4;
  }
  if (upper.startsWith("SF") || upper.includes("SEMI")) {
    return 5;
  }
  if (
    upper.startsWith("F ") ||
    upper.startsWith("F#") ||
    upper.startsWith("F_") ||
    upper.startsWith("F1") ||
    upper.startsWith("F2") ||
    upper.includes("FINAL")
  ) {
    return 6;
  }
  if (upper.includes("TOP") || upper.includes("ROUND ROBIN")) {
    return 7;
  }
  return 99;
}

export function extractTrailingNumber(name: string): number {
  let i = name.length - 1;
  while (i >= 0 && name[i] >= "0" && name[i] <= "9") {
    i--;
  }
  if (i === name.length - 1) return 0;
  return parseInt(name.slice(i + 1), 10);
}

export function matchComparison(
  a: IncidentMatch | undefined,
  b: IncidentMatch | undefined,
  matchMap?: Map<number, MatchData>
) {
  if (!a && !b) {
    return 0;
  }

  if (!a) {
    return -1;
  }

  if (!b) {
    return 1;
  }

  if (a.type === "skills" && b.type === "skills") {
    return `${a.skillsType}${a.attempt}`.localeCompare(
      `${b.skillsType}${b.attempt}`
    );
  }

  if (a.type === "match" && b.type === "skills") {
    return -1;
  }

  if (a.type === "skills" && b.type === "match") {
    return 1;
  }

  if (a.type === "match" && b.type === "match") {
    if (a.division !== b.division) {
      return a.division - b.division;
    }

    const matchDataA = matchMap?.get(a.id);
    const matchDataB = matchMap?.get(b.id);

    const orderA = getMatchRoundOrder(a, matchDataA);
    const orderB = getMatchRoundOrder(b, matchDataB);

    if (orderA !== orderB) {
      return orderA - orderB;
    }

    if (matchDataA && matchDataB) {
      if (matchDataA.instance !== matchDataB.instance) {
        return matchDataA.instance - matchDataB.instance;
      }

      if (matchDataA.matchnum !== matchDataB.matchnum) {
        return matchDataA.matchnum - matchDataB.matchnum;
      }

      return 0;
    }

    const instanceA = extractTrailingNumber(a.name);
    const instanceB = extractTrailingNumber(b.name);

    if (instanceA !== instanceB) {
      return instanceA - instanceB;
    }

    return a.name.localeCompare(b.name);
  }

  return 0;
}

export function incidentComparison(
  a: Incident,
  b: Incident,
  matchMap?: Map<number, MatchData>
): number {
  const teamComparisonResult = teamComparison(a.team, b.team);
  if (teamComparisonResult !== 0) {
    return teamComparisonResult;
  }

  const matchComparisonResult = matchComparison(a.match, b.match, matchMap);
  if (matchComparisonResult !== 0) {
    return matchComparisonResult;
  }

  return (
    new Date(a.consistency.outcome.instant).getTime() -
    new Date(b.consistency.outcome.instant).getTime()
  );
}

export async function generateIncidentReportPDF({
  sku,
  users,
  client,
  incidents,
  formatters,
}: GenerateIncidentReportPDFOptions): Promise<ArrayBuffer | null> {
  const event = await client.events.getBySKU(sku);
  if (!event.data) {
    return null;
  }

  const document = new jsPDF({
    unit: "px",
    orientation: "portrait",
    compress: true,
    format: "letter",
  });

  // Header
  document.setFont("helvetica", "bold");
  document.setFontSize(18);
  document.text("Referee Match Anomaly Log", 16, 16);

  document.setFont("helvetica", "italic");
  document.setFontSize(12);
  document.text(event.data.name, 16, 30);

  const date = formatters.date.format(new Date());

  document.setFont("helvetica", "normal");
  document.setFontSize(12);
  document.text(
    `This anomaly log was generated by RoboRef at ${date}.`,
    16,
    44
  );

  const data: IncidentRow[] = [];

  const divisionsToFetch = new Set<number>();
  for (const incident of incidents) {
    if (incident.match?.type === "match") {
      divisionsToFetch.add(incident.match.division);
    }
  }

  const matchMap = new Map<number, MatchData>();
  await Promise.all(
    Array.from(divisionsToFetch).map(async (division) => {
      try {
        const matchesResponse = await event.data.matches(division);
        if (matchesResponse.data) {
          for (const match of matchesResponse.data) {
            matchMap.set(match.id, match);
          }
        }
      } catch {
        // Fall back gracefully if division matches cannot be fetched
      }
    })
  );

  const incidentsInOrder = [...incidents].sort((a, b) =>
    incidentComparison(a, b, matchMap)
  );

  for (const incident of incidentsInOrder) {
    const contact = users.find(
      (user) => user.key === incident.consistency.outcome.peer
    );

    let team = incident.team;
    if (incident.flags?.includes("judge")) {
      team = `[J] ${team}`;
    }

    data.push({
      team,
      match: incidentMatchNameToString(incident.match),
      rule: incident.outcome + " " + incident.rules.join(", "),
      contact: contact?.name ?? "",
      notes: incident.notes ?? "None",
    });
  }

  const headers: CellConfig[] = [
    {
      name: "team",
      prompt: "Team",
      align: "left",
      width: 80,
      padding: 2,
    },
    {
      name: "match",
      prompt: "Match",
      align: "left",
      width: 90,
      padding: 2,
    },
    {
      name: "rule",
      prompt: "Rule",
      align: "left",
      width: 120,
      padding: 2,
    },
    {
      name: "contact",
      prompt: "Contact",
      align: "left",
      width: 100,
      padding: 2,
    },
    {
      name: "notes",
      prompt: "Notes",
      align: "left",
      width: 180,
      padding: 2,
    },
  ];

  document.setFont("helvetica", "normal");
  document.table(16, 56, data, headers, {
    autoSize: false,
  });

  return document.output("arraybuffer");
}
