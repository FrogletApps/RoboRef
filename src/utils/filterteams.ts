import { TeamData } from "@roboref/vexevents";

export const filterTeams = (
  teams: TeamData[],
  filter: string | null,
  matchTeamNumbers?: Set<string>
): TeamData[] => {
  if (!filter || !filter.trim()) return teams;

  const fRaw = filter.trim().toUpperCase();
  const fNorm = fRaw.replace(/[^A-Z0-9]/g, "");

  return teams?.filter((team) => {
    const numRaw = team.number?.toUpperCase() ?? "";
    const nameRaw = team.team_name?.toUpperCase() ?? "";
    const orgRaw = team.organization?.toUpperCase() ?? "";

    if (
      numRaw.includes(fRaw) ||
      nameRaw.includes(fRaw) ||
      orgRaw.includes(fRaw) ||
      (matchTeamNumbers && matchTeamNumbers.has(numRaw))
    ) {
      return true;
    }

    if (fNorm.length > 0) {
      const numNorm = numRaw.replace(/[^A-Z0-9]/g, "");
      const nameNorm = nameRaw.replace(/[^A-Z0-9]/g, "");
      const orgNorm = orgRaw.replace(/[^A-Z0-9]/g, "");

      if (
        numNorm.includes(fNorm) ||
        nameNorm.includes(fNorm) ||
        orgNorm.includes(fNorm)
      ) {
        return true;
      }
    }

    return false;
  });
};
