import { bench, run } from "mitata";

const generateMatches = (count: number) => {
    return Array.from({ length: count }, (_, i) => ({ id: i, data: `match-${i}` }));
}

const allTeamMatches = generateMatches(1000);
const matchToFind = 999;

let globalSum = 0;

bench("Linear search find", () => {
    const m = allTeamMatches.find((m) => m.id === matchToFind);
    globalSum += m?.id || 0;
});

// Since we cannot run renderHook due to no DOM, let's just benchmark the map construction + get vs linear find
// This simulates the worst case of useMemo when the memoized value needs to be recomputed
bench("Map construction + get", () => {
    const map = new Map();
    for (const match of allTeamMatches) {
        map.set(match.id, match);
    }
    const m = map.get(matchToFind);
    globalSum += m?.id || 0;
});

const matchMap = new Map();
for (const match of allTeamMatches) {
    matchMap.set(match.id, match);
}

bench("Pure map lookup (best case)", () => {
    const m = matchMap.get(matchToFind);
    globalSum += m?.id || 0;
})

await run();
console.log(globalSum);
