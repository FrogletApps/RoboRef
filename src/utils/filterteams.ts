import { TeamData } from "@roboref/vexevents";

export const filterTeams = (
  teams: TeamData[],
  filter: string | null
): TeamData[] => {
  if (!filter) return teams;

  const f = filter.toUpperCase();

  return teams?.filter(
    (team) =>
      team.number.toUpperCase().startsWith(f) ||
      team.team_name?.toUpperCase().includes(f)
  );
};
