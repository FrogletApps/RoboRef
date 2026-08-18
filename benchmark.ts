const teamMatches = Array.from({ length: 100 }, (_, i) => ({
  id: i,
  name: `Q${i + 1}`,
  division: {
    id: 1,
    name: "Division 1"
  }
}));

const matchById = new Map();
for (const match of teamMatches) {
  matchById.set(`${match.division.id}@${match.name}`, match);
}

const targetValue = "1@Q90";

const iterations = 1000000;

const startFind = performance.now();
for (let i = 0; i < iterations; i++) {
  const [division, name] = targetValue.split("@");
  teamMatches.find(match => match.division.id === Number.parseInt(division) && match.name === name);
}
const endFind = performance.now();
console.log(`Array.find: ${endFind - startFind}ms`);

const startMap = performance.now();
for (let i = 0; i < iterations; i++) {
  matchById.get(targetValue);
}
const endMap = performance.now();
console.log(`Map.get: ${endMap - startMap}ms`);
