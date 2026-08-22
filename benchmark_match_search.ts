import { performance } from "perf_hooks";

// Mock data
const generateMatches = (count: number) => {
  return Array.from({ length: count }).map((_, i) => ({
    name: `Match ${i} Name with some extra text`,
    shortName: () => `M${i}`,
    id: i,
    alliances: [
      { teams: [{ team: { name: `123${i}A` } }] },
      { teams: [{ team: { name: `456${i}B` } }] }
    ]
  }));
};

const matches = generateMatches(10000);
const filters = ["m", "match", "extra text", "M123", "nonexistent", "123", " "];

const runCurrent = () => {
  for (const filter of filters) {
    const set = new Set<string>();
    if (!matches || !filter.trim()) continue;

    const qRaw = filter.trim().toLowerCase();
    const qNorm = qRaw.replace(/[^a-z0-9]/g, "");

    for (const match of matches) {
      const matchNameRaw = (match.name ?? "").toLowerCase();
      const shortNameRaw = (match.shortName ? match.shortName() : "").toLowerCase();
      const matchIdStr = match.id?.toString() ?? "";

      let isMatch =
        matchNameRaw.includes(qRaw) ||
        shortNameRaw.includes(qRaw) ||
        matchIdStr === qRaw;

      if (!isMatch && qNorm.length > 0) {
        const matchNameNorm = matchNameRaw.replace(/[^a-z0-9]/g, "");
        const shortNameNorm = shortNameRaw.replace(/[^a-z0-9]/g, "");
        isMatch =
          matchNameNorm.includes(qNorm) ||
          shortNameNorm.includes(qNorm) ||
          matchIdStr === qNorm;
      }

      if (isMatch) {
        for (const alliance of match.alliances ?? []) {
          for (const t of alliance.teams ?? []) {
            if (t.team?.name) {
              set.add(t.team.name.toUpperCase());
            }
          }
        }
      }
    }
  }
};

const runOptimized = () => {
  // Pre-calculate normalized names
  const normalizedMatches = matches.map(match => {
      const matchNameRaw = (match.name ?? "").toLowerCase();
      const shortNameRaw = (match.shortName ? match.shortName() : "").toLowerCase();
      return {
          match,
          matchNameRaw,
          shortNameRaw,
          matchIdStr: match.id?.toString() ?? "",
          matchNameNorm: matchNameRaw.replace(/[^a-z0-9]/g, ""),
          shortNameNorm: shortNameRaw.replace(/[^a-z0-9]/g, "")
      };
  });

  for (const filter of filters) {
    const set = new Set<string>();
    if (!normalizedMatches || !filter.trim()) continue;

    const qRaw = filter.trim().toLowerCase();
    const qNorm = qRaw.replace(/[^a-z0-9]/g, "");

    for (const normMatch of normalizedMatches) {
      let isMatch =
        normMatch.matchNameRaw.includes(qRaw) ||
        normMatch.shortNameRaw.includes(qRaw) ||
        normMatch.matchIdStr === qRaw;

      if (!isMatch && qNorm.length > 0) {
        isMatch =
          normMatch.matchNameNorm.includes(qNorm) ||
          normMatch.shortNameNorm.includes(qNorm) ||
          normMatch.matchIdStr === qNorm;
      }

      if (isMatch) {
        for (const alliance of normMatch.match.alliances ?? []) {
          for (const t of alliance.teams ?? []) {
            if (t.team?.name) {
              set.add(t.team.name.toUpperCase());
            }
          }
        }
      }
    }
  }
};

const bench = (name: string, fn: () => void) => {
  const start = performance.now();
  for (let i = 0; i < 100; i++) {
    fn();
  }
  const end = performance.now();
  console.log(`${name}: ${end - start} ms`);
};

bench("Current", runCurrent);
bench("Optimized", runOptimized);
