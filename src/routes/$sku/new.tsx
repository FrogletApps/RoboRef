import {
  useEventMatches,
  useEventTeams,
  useEventMatch,
  useEventTeam,
  useEventMatchesForTeam,
} from "~hooks/robotevents";
import { Rule, useRulesForEvent } from "~utils/hooks/rules";
import {
  Checkbox,
  Radio,
  RulesMultiSelect,
  Select,
  TextArea,
} from "~components/Input";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Button, IconButton } from "~components/Button";
import { MatchContext } from "~components/Context";
import { useCurrentDivision, useCurrentEvent } from "~hooks/state";
import {
  IncidentOutcome,
  RichIncident,
  packIncident,
} from "~utils/data/incident";
import { useNewIncident } from "~hooks/incident";
import { useAddRecentRules, useRecentRules } from "~utils/hooks/history";
import { twMerge } from "tailwind-merge";
import { toast } from "~components/Toast";
import { Spinner } from "~components/Spinner";
import { MatchData, programs } from "@referee-fyi/robotevents";
import { queryClient } from "~utils/data/query";
import { IncidentFlag, IncidentMatchSkills } from "@referee-fyi/share";
import { AssetPicker, LocalAssetPreview } from "~components/Assets";
import { LocalAsset } from "~utils/data/assets";
import {
  CameraIcon,
  TrashIcon,
  ArrowUpTrayIcon,
} from "@heroicons/react/20/solid";
import { useSaveAssets } from "~utils/hooks/assets";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";

const ENABLE_IMAGE_UPLOAD = false;

export const NewEntryPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku } = useParams({ strict: false });
  const search = Route.useSearch();

  const initialTeam = search.team;
  const initialMatchId = search.match ? Number(search.match) : undefined;
  const isSkillsInitial = search.skills;

  const { mutateAsync: createIncident } = useNewIncident();
  const { data: event, isLoading: isLoadingEvent } = useCurrentEvent();
  const division = useCurrentDivision();

  const { data: rules } = useRulesForEvent(event);
  const { data: recentRules } = useRecentRules(
    event?.program.id ?? programs.V5RC,
    event?.season.id ?? 0,
    4
  );
  const { mutateAsync: addRecentRules } = useAddRecentRules(
    event?.program.id ?? programs.V5RC,
    event?.season.id ?? 0
  );

  const { data: teams, isLoading: isLoadingTeams } = useEventTeams(event);
  const { data: matches, isLoading: isLoadingMatches } = useEventMatches(
    event,
    division
  );

  const [team, setTeam] = useState<string | undefined>(initialTeam);
  const [match, setMatch] = useState<number | undefined>(initialMatchId);

  const { data: teamData } = useEventTeam(event, team);
  const { data: eventMatchData } = useEventMatch(event, division, match);

  const { data: allTeamMatches, isLoading: isLoadingAllTeamMatches } =
    useEventMatchesForTeam(event, teamData, undefined, {
      enabled: !division,
    });

  const allTeamsMatchesMatchData = allTeamMatches?.find((m) => m.id === match);
  const matchData = eventMatchData ?? allTeamsMatchesMatchData;

  const teamMatches = useMemo(() => {
    if (!team) return [];
    if (!division && allTeamMatches) return allTeamMatches;

    return (
      matches?.filter((m) => {
        const teamNames = m.alliances
          .map((a) => a.teams.map((t) => t.team?.name))
          .flat();
        return teamNames.includes(team);
      }) ?? []
    );
  }, [matches, team, allTeamMatches, division]);

  const teamMatchesByDiv = useMemo(() => {
    const divisions: Record<string, MatchData[]> = {};
    for (const match of teamMatches) {
      if (divisions[match.division.name]) {
        divisions[match.division.name].push(match);
      } else {
        divisions[match.division.name] = [match];
      }
    }
    return Object.entries(divisions);
  }, [teamMatches]);

  const isLoadingMetaData =
    isLoadingEvent ||
    isLoadingTeams ||
    isLoadingMatches ||
    isLoadingAllTeamMatches;

  const [incident, setIncident] = useState<RichIncident>({
    time: new Date(),
    event: sku ?? "",
    team: teamData?.number,
    match: matchData,
    skills: isSkillsInitial
      ? { type: "skills", skillsType: "driver", attempt: 1 }
      : undefined,
    rules: [],
    notes: "",
    outcome: search.outcome ?? "Minor",
    assets: [],
    flags: [],
  });

  useEffect(() => {
    setIncidentField("team", teamData?.number);
    setIncidentField("match", matchData);
  }, [teamData, matchData]);

  const canSave = useMemo(() => {
    if (isLoadingMetaData || !incident.team || !event) return false;
    return true;
  }, [incident.team, isLoadingMetaData, event]);

  const setIncidentField = <T extends keyof RichIncident>(
    key: T,
    value: RichIncident[T]
  ) => {
    setIncident((i) => ({ ...i, [key]: value }));
  };

  const onChangeIncidentTeam = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      const newTeam = teams?.find((t) => t.number === e.target.value);
      if (e.target.value === "-1") {
        setMatch(undefined);
        setTeam(undefined);
      }
      setIncidentField("team", newTeam?.number);
      setTeam(newTeam?.number);
    },
    [teams]
  );

  const onChangeIncidentMatch = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      if (e.target.value === "0") {
        setIncidentField("match", undefined);
        setIncidentField("skills", {
          type: "skills",
          skillsType: "driver",
          attempt: 1,
        });
        setMatch(undefined);
        return;
      }

      let matchPool = matches;
      if (!division) matchPool = allTeamMatches;

      const newMatch = matchPool?.find(
        (m) => m.id.toString() === e.target.value
      );

      if (e.target.value === "-1") {
        setMatch(undefined);
        setTeam(undefined);
        setIncidentField("skills", undefined);
      }

      if (!newMatch) return;

      setIncidentField("match", newMatch);
      setIncidentField("skills", undefined);
      setMatch(newMatch.id);
    },
    [matches, allTeamMatches, division]
  );

  const onChangeIncidentSkillsType = useCallback(
    (type: IncidentMatchSkills["skillsType"]) => {
      if (incident.skills) {
        setIncidentField("skills", { ...incident.skills, skillsType: type });
      }
    },
    [incident]
  );

  const onChangeIncidentSkillsAttempt = useCallback(
    (attempt: number) => {
      if (incident.skills) {
        setIncidentField("skills", { ...incident.skills, attempt });
      }
    },
    [incident]
  );

  const onChangeIncidentOutcome = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      setIncidentField("outcome", e.target.value as IncidentOutcome);
    },
    []
  );

  const onAddRule = useCallback(
    (rule: Rule) => {
      if (incident.rules.some((r) => r.rule === rule.rule)) return;
      setIncidentField("rules", [...incident.rules, rule]);
    },
    [incident.rules]
  );

  const onRemoveRule = useCallback(
    (rule: Rule) => {
      setIncidentField(
        "rules",
        incident.rules.filter((r) => r.rule !== rule.rule)
      );
    },
    [incident.rules]
  );

  const onToggleRule = useCallback(
    (rule: Rule) => {
      if (incident.rules.some((r) => r.rule === rule.rule)) {
        onRemoveRule(rule);
      } else {
        onAddRule(rule);
      }
    },
    [incident.rules, onAddRule, onRemoveRule]
  );

  const onChangeIncidentRules = useCallback((rules: Rule[]) => {
    setIncidentField("rules", rules);
  }, []);

  const onPickAsset = useCallback(
    (asset: LocalAsset) => {
      setIncidentField("assets", [...incident.assets, asset]);
    },
    [incident.assets]
  );

  const onRemoveAsset = useCallback(
    (asset: LocalAsset) => {
      setIncidentField(
        "assets",
        incident.assets.filter((a) => a.id !== asset.id)
      );
    },
    [incident.assets]
  );

  const onChangeIncidentNotes = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      setIncidentField("notes", e.target.value);
    },
    []
  );

  const onChangeFlag = useCallback(
    (flag: IncidentFlag, value: boolean) => {
      if (value) {
        setIncidentField("flags", [...(incident.flags ?? []), flag]);
      } else {
        setIncidentField(
          "flags",
          incident.flags?.filter((f) => f !== flag) ?? []
        );
      }
    },
    [incident.flags]
  );

  const { mutateAsync: saveAssets } = useSaveAssets(incident.assets);
  const onSubmit = useCallback(
    async (e: React.FormEvent<HTMLFormElement> | React.MouseEvent) => {
      e.preventDefault();

      const packed = packIncident(incident);

      try {
        await saveAssets();
        await createIncident(packed);

        addRecentRules(incident.rules);
        toast({ type: "info", message: "Created Entry" });

        queryClient.invalidateQueries({ queryKey: ["incidents"] });

        if (router.history.canGoBack()) {
          router.history.back();
        } else {
          navigate({ to: "/$sku", params: { sku: sku ?? "" } });
        }
      } catch (e) {
        toast({
          type: "error",
          message: "Could not create entry!",
          context: JSON.stringify(e),
        });
      }
    },
    [incident, saveAssets, createIncident, addRecentRules, router, navigate, sku]
  );

  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto p-4">
      <Spinner show={isLoadingMetaData} />
      <label>
        <p className="mt-2 font-medium">Match</p>
        <Select
          value={incident.skills ? 0 : (incident.match?.id ?? -1)}
          onChange={onChangeIncidentMatch}
          className="max-w-full w-full mt-1"
        >
          <option value={-1}>Pick A Match</option>
          <option value={0}>Skills</option>
          {team &&
            teamMatchesByDiv?.map(([name, matches]) => (
              <optgroup label={name} key={name}>
                {matches.map((match) => (
                  <option value={match.id} key={match.id}>
                    {match.name}
                  </option>
                ))}
              </optgroup>
            ))}
          {!team &&
            matches?.map((match) => (
              <option value={match.id} key={match.id}>
                {match.name}
              </option>
            ))}
        </Select>
      </label>

      {incident.skills ? (
        <div
          className="flex gap-2 mt-2"
          role="radiogroup"
          aria-label="Skills Match"
        >
          <Radio
            name="skillsType"
            label="Driver"
            bind={{
              value: incident.skills.skillsType,
              onChange: onChangeIncidentSkillsType,
              variant: "driver",
            }}
          />
          <Radio
            name="skillsType"
            label="Auto"
            bind={{
              value: incident.skills.skillsType,
              onChange: onChangeIncidentSkillsType,
              variant: "programming",
            }}
          />
          <Radio
            name="skillsAttempt"
            label="1"
            className="flex-1 ml-4"
            bind={{
              value: incident.skills.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 1,
            }}
          />
          <Radio
            name="skillsAttempt"
            label="2"
            className="flex-1"
            bind={{
              value: incident.skills.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 2,
            }}
          />
          <Radio
            name="skillsAttempt"
            label="3"
            className="flex-1"
            bind={{
              value: incident.skills.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 3,
            }}
          />
        </div>
      ) : null}

      {incident.match && (
        <MatchContext
          match={incident.match}
          className="mt-4 justify-between"
          parts={{ alliance: { className: "w-full" } }}
        />
      )}

      <label>
        <p className="mt-4 font-medium">Team</p>
        <Select
          value={incident.team ?? -1}
          onChange={onChangeIncidentTeam}
          className="max-w-full w-full mt-1"
        >
          <option value={-1}>Pick A Team</option>
          {matchData?.alliances.map((alliance) => (
            <optgroup
              key={alliance.color.toUpperCase()}
              label={alliance.color.toUpperCase()}
            >
              {alliance.teams.map(({ team }) => (
                <option value={team?.name} key={team?.id}>
                  {team?.name}
                </option>
              ))}
            </optgroup>
          ))}
          {!match &&
            teams?.map((team) => (
              <option value={team.number} key={team.id}>
                {team.number}
              </option>
            ))}
        </Select>
      </label>

      <label>
        <p className="mt-4 font-medium">Outcome</p>
        <Select
          value={incident.outcome}
          onChange={onChangeIncidentOutcome}
          className="max-w-full w-full mt-1"
        >
          <option value="General">General</option>
          <option value="Inspection">Inspection</option>
          <option value="Minor">Minor</option>
          <option value="Major">Major</option>
          <option value="Disabled">Disabled</option>
        </Select>
      </label>

      <div>
        <p className="mt-4 font-medium">Associated Rules</p>
        <div className="flex mt-2 gap-2 flex-wrap md:flex-nowrap">
          {recentRules?.map((rule) => (
            <Button
              mode="none"
              className={twMerge(
                "text-emerald-400 font-mono min-w-min flex-shrink",
                incident.rules.some((r) => r.rule === rule.rule)
                  ? "bg-emerald-600 text-zinc-50"
                  : ""
              )}
              onClick={() => onToggleRule(rule)}
              key={rule.rule}
            >
              <div className="flex items-center gap-x-1">
                {rule.rule}
                {rule.icon && (
                  <img
                    src={rule.icon}
                    alt={`Icon`}
                    className="max-h-6 w-auto"
                  />
                )}
              </div>
            </Button>
          ))}
        </div>
        <RulesMultiSelect
          game={rules!}
          value={incident.rules}
          onChange={onChangeIncidentRules}
        />
      </div>

      <div>
        <p className="mt-4 font-medium">Images</p>
        <section className="grid grid-cols-4 gap-2 mt-2">
          {incident.assets.map((asset) => (
            <div className="relative" key={asset.id}>
              <IconButton
                className="absolute top-0 right-0 p-2 rounded-none rounded-bl-md rounded-tr-md bg-red-500"
                icon={<TrashIcon height={16} />}
                onClick={() => onRemoveAsset(asset)}
              />
              <LocalAssetPreview key={asset.id} asset={asset} />
            </div>
          ))}
        </section>
        <label
          className={twMerge(
            "bg-zinc-700 rounded-md flex gap-2 items-center justify-center active:bg-zinc-800 focus-within:bg-zinc-800 focus-within:ring-2 ring-zinc-200 cursor-pointer px-3 py-2 mt-4",
            !ENABLE_IMAGE_UPLOAD && "opacity-50 cursor-not-allowed"
          )}
          aria-disabled={!ENABLE_IMAGE_UPLOAD}
        >
          <CameraIcon className="w-8 h-8 text-zinc-50" />
          <span>Capture</span>
          <AssetPicker
            capture="environment"
            accept="image/*"
            className="sr-only"
            fields={{ type: "image" }}
            onPick={onPickAsset}
            disabled={!ENABLE_IMAGE_UPLOAD}
          />
        </label>
        <label
          className={twMerge(
            "bg-zinc-700 rounded-md flex gap-2 items-center justify-center active:bg-zinc-800 focus-within:bg-zinc-800 focus-within:ring-2 ring-zinc-200 cursor-pointer px-3 py-2 mt-4",
            !ENABLE_IMAGE_UPLOAD && "opacity-50 cursor-not-allowed"
          )}
          aria-disabled={!ENABLE_IMAGE_UPLOAD}
        >
          <ArrowUpTrayIcon className="w-8 h-8 text-zinc-50" />
          <span>Upload</span>
          <AssetPicker
            accept="image/*"
            className="sr-only"
            fields={{ type: "image" }}
            onPick={onPickAsset}
            disabled={!ENABLE_IMAGE_UPLOAD}
          />
        </label>
      </div>

      <label>
        <p className="mt-4 font-medium">Notes</p>
        <TextArea
          className="w-full mt-2 h-32"
          value={incident.notes}
          onChange={onChangeIncidentNotes}
        />
      </label>

      <label>
        <p className="mt-4 font-medium">Flag For Review</p>
        <Checkbox
          label="Judging"
          bind={{
            value: incident.flags?.includes("judge") ?? false,
            onChange: (value) => onChangeFlag("judge", value),
          }}
        />
      </label>

      <Button
        className="w-full text-center my-6 bg-emerald-400 text-black font-semibold"
        disabled={!canSave}
        onClick={onSubmit}
      >
        Submit Entry
      </Button>
    </main>
  );
};

export type NewEntrySearch = {
  team?: string;
  match?: number;
  skills?: boolean;
  outcome?: IncidentOutcome;
};

export const Route = createFileRoute("/$sku/new")({
  validateSearch: (search: Record<string, unknown>): NewEntrySearch => ({
    team: typeof search.team === "string" ? search.team : undefined,
    match: typeof search.match === "number" ? search.match : typeof search.match === "string" ? parseInt(search.match, 10) : undefined,
    skills: search.skills === true || search.skills === "true",
    outcome: typeof search.outcome === "string" ? (search.outcome as IncidentOutcome) : undefined,
  }),
  component: NewEntryPage,
});
