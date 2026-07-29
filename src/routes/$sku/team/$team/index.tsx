import { useEventMatchesForTeam, useEventTeam } from "~hooks/robotevents";
import { Spinner } from "~components/Spinner";
import { useCallback, useMemo, useState } from "react";
import { useCurrentEvent } from "~hooks/state";
import { useTeamIncidentsByEvent } from "~hooks/incident";
import { EventData, TeamData, MatchData } from "@referee-fyi/robotevents";
import { ClickableMatch } from "~components/Match";
import { Incident } from "~components/Incident";
import { PlusIcon } from "@heroicons/react/24/outline";
import { ChevronDownIcon, ChevronRightIcon } from "@heroicons/react/20/solid";
import { useEventAssetsForTeam } from "~utils/hooks/assets";
import { AssetPreview } from "~components/Assets";
import { createFileRoute, useNavigate, useParams } from "@tanstack/react-router";
import { LinkButton } from "~components/Button";
import { NoteSummaryPills } from "~components/RulesSummary";

type SectionId = "summary" | "schedule" | "images";

export type TeamImagesSectionProps = {
  teamNumber?: string;
  team?: string;
  sku?: string;
  isOpen: boolean;
  onToggle: () => void;
};

export const TeamImagesSection: React.FC<TeamImagesSectionProps> = ({
  teamNumber,
  team,
  sku,
  isOpen,
  onToggle,
}) => {
  const targetTeam = teamNumber ?? team;
  const assets = useEventAssetsForTeam(sku, targetTeam);

  if (!assets || assets.length === 0) return null;

  return (
    <div className="border border-zinc-800 rounded-lg overflow-hidden my-2 flex-shrink-0">
      <button
        type="button"
        onClick={onToggle}
        className="w-full text-left flex gap-2 items-center justify-between cursor-pointer select-none active:bg-zinc-800 bg-zinc-900 py-3 px-4 z-10 border-b border-zinc-800"
      >
        <div className="flex items-center gap-2 flex-shrink-0">
          {isOpen ? (
            <ChevronDownIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          ) : (
            <ChevronRightIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          )}
          <h2 className="font-semibold text-zinc-100 flex-shrink-0">Team Images</h2>
        </div>
        <span className="text-xs font-mono text-zinc-400 ml-auto">
          {assets.length} {assets.length === 1 ? "image" : "images"}
        </span>
      </button>
      {isOpen && (
        <div className="p-2 bg-zinc-900/50 max-h-[45vh] overflow-y-auto grid lg:grid-cols-6 grid-cols-2 md:grid-cols-3 gap-2">
          {assets.map((asset) => (asset ? <AssetPreview asset={asset} key={asset} /> : null))}
        </div>
      )}
    </div>
  );
};

export const TeamNoteSummarySection: React.FC<{
  teamNumber?: string;
  sku?: string;
  isOpen: boolean;
  onToggle: () => void;
}> = ({ teamNumber, sku, isOpen, onToggle }) => {
  const { data: incidents, isLoading } = useTeamIncidentsByEvent(teamNumber, sku);

  return (
    <div className={`border border-zinc-800 rounded-lg overflow-hidden flex flex-col ${isOpen ? "flex-1 min-h-0" : "flex-shrink-0"} my-1`}>
      <button
        type="button"
        onClick={onToggle}
        className="w-full text-left flex gap-2 items-center justify-between cursor-pointer select-none active:bg-zinc-800 bg-zinc-900 py-3 px-4 z-10 border-b border-zinc-800 flex-shrink-0"
      >
        <div className="flex items-center gap-2 flex-shrink-0">
          {isOpen ? (
            <ChevronDownIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          ) : (
            <ChevronRightIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          )}
          <h2 className="font-semibold text-zinc-100 flex-shrink-0">Team Note Summary</h2>
        </div>
        {incidents ? (
          <span className="text-xs font-mono text-zinc-400 ml-auto">
            {incidents.length} {incidents.length === 1 ? "Note" : "Notes"}
          </span>
        ) : null}
      </button>
      {isOpen && (
        <div className="p-2 bg-zinc-900/50 flex-1 min-h-0 overflow-y-auto">
          <Spinner show={isLoading} />
          {incidents && incidents.length > 0 ? (
            <>
              <NoteSummaryPills incidents={incidents} />
              <div className="flex flex-col gap-2">
                {incidents.map((incident) => (
                  <Incident incident={incident} key={incident.id} className="h-20" />
                ))}
              </div>
            </>
          ) : (
            <p className="p-2 text-sm text-zinc-400 italic">No Notes Recorded!</p>
          )}
        </div>
      )}
    </div>
  );
};

export const TeamMatchScheduleSection: React.FC<{
  event: EventData | null | undefined;
  team: TeamData | null | undefined;
  isOpen: boolean;
  onToggle: () => void;
}> = ({ event, team, isOpen, onToggle }) => {
  const { data: matches, isLoading } = useEventMatchesForTeam(event, team);
  const navigate = useNavigate();

  const onClickMatch = useCallback(
    (match: MatchData) => {
      if (!event) return;
      navigate({
        to: "/$sku/match/$matchId",
        params: { sku: event.sku, matchId: match.id.toString() },
      });
    },
    [event, navigate]
  );

  return (
    <div className={`border border-zinc-800 rounded-lg overflow-hidden flex flex-col ${isOpen ? "flex-1 min-h-0" : "flex-shrink-0"} my-1`}>
      <button
        type="button"
        onClick={onToggle}
        className="w-full text-left flex gap-2 items-center justify-between cursor-pointer select-none active:bg-zinc-800 bg-zinc-900 py-3 px-4 z-10 border-b border-zinc-800 flex-shrink-0"
      >
        <div className="flex items-center gap-2 flex-shrink-0">
          {isOpen ? (
            <ChevronDownIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          ) : (
            <ChevronRightIcon height={18} width={18} className="flex-shrink-0 text-zinc-400" />
          )}
          <h2 className="font-semibold text-zinc-100 flex-shrink-0">Match Schedule</h2>
        </div>
        {matches ? (
          <span className="text-xs font-mono text-zinc-400 ml-auto">
            {matches.length} {matches.length === 1 ? "match" : "matches"}
          </span>
        ) : null}
      </button>
      {isOpen && (
        <div className="p-2 bg-zinc-900/50 flex-1 min-h-0 overflow-y-auto">
          <Spinner show={isLoading} />
          {matches && matches.length > 0 ? (
            <ul className="divide-y divide-zinc-800">
              {matches.map((match) => (
                <ClickableMatch
                  match={match}
                  selectedTeam={team?.number}
                  key={match.id}
                  onClick={() => onClickMatch(match)}
                />
              ))}
            </ul>
          ) : (
            <p className="p-2 text-sm text-zinc-400 italic">No matches scheduled</p>
          )}
        </div>
      )}
    </div>
  );
};

export const EventTeamsPage: React.FC = () => {
  const { team: number } = useParams({ strict: false });
  const { data: event } = useCurrentEvent();
  const { data: team } = useEventTeam(event, number ?? "");

  const [openSection, setOpenSection] = useState<SectionId | null>("summary");

  const toggleSection = (id: SectionId) => {
    setOpenSection((prev) => (prev === id ? null : id));
  };

  const teamLocation = useMemo(() => {
    if (!team) return null;
    return [
      team?.location?.city,
      team?.location?.region,
      team?.location?.country,
    ]
      .filter((v) => !!v)
      .join(", ");
  }, [team]);

  return (
    <section className="flex flex-col h-full min-h-0 overflow-hidden pb-2">
      <header className="flex items-center justify-between gap-4 mt-2 mb-2 flex-shrink-0">
        <div className="min-w-0 flex-1">
          <h1 className="text-xl overflow-hidden whitespace-nowrap text-ellipsis max-w-[20ch] lg:max-w-prose">
            <span className="font-mono text-emerald-400">{number}</span>
            {" • "}
            <span>{team?.team_name}</span>
          </h1>
          <p className="italic text-sm text-zinc-400">{teamLocation}</p>
        </div>
        <LinkButton
          to="/$sku/new"
          params={{ sku: event?.sku ?? "" }}
          search={{ team: number ?? "" }}
          className="bg-emerald-600 active:bg-emerald-700 text-white font-semibold flex items-center justify-center gap-1.5 px-3 py-2 rounded-md shrink-0"
        >
          <PlusIcon height={20} className="w-5 h-5" />
          <span>New Note</span>
        </LinkButton>
      </header>

      <TeamNoteSummarySection
        teamNumber={number}
        sku={event?.sku}
        isOpen={openSection === "summary"}
        onToggle={() => toggleSection("summary")}
      />
      <div className={openSection === "summary" ? "mt-auto flex-shrink-0 flex flex-col" : "flex-1 min-h-0 flex flex-col"}>
        <TeamMatchScheduleSection
          event={event}
          team={team}
          isOpen={openSection === "schedule"}
          onToggle={() => toggleSection("schedule")}
        />
        <TeamImagesSection
          teamNumber={number}
          sku={event?.sku}
          isOpen={openSection === "images"}
          onToggle={() => toggleSection("images")}
        />
      </div>
    </section>
  );
};

export const Route = createFileRoute("/$sku/team/$team/")({
  component: EventTeamsPage,
});
