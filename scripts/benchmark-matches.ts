import { bench, run } from "mitata";

const generateMatches = (count: number) => {
    return Array.from({ length: count }, (_, i) => ({ id: i, data: `match-${i}` }));
}

const allTeamMatches = generateMatches(1000);
const matchToFind = 999;

bench("Linear search", () => {
    return allTeamMatches.find((m) => m.id === matchToFind);
});

const allTeamMatchesMap = new Map();
for (const match of allTeamMatches) {
    allTeamMatchesMap.set(match.id, match);
}

bench("Map lookup", () => {
    return allTeamMatchesMap.get(matchToFind);
});

await run();
