import { TeamData } from "@referee-fyi/robotevents";

export const filterTeams = (
  teams: TeamData[],
  filter: string | null
): TeamData[] => {
  if (!filter) return teams;

  return teams?.filter(
    (team) =>
      team.number.startsWith(filter) ||
      team.team_name?.toUpperCase().includes(filter)
  );
};
