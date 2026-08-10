import React, { useCallback, useEffect, useMemo, useState } from "react";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";
import { MatchData } from "@roboref/robotevents";
import { Button, IconButton } from "~components/Button";
import {
  Checkbox,
  Radio,
  RulesMultiSelect,
  Select,
  TextArea,
} from "~components/Input";
import { toast } from "~components/Toast";
import {
  IncidentFlag,
  IncidentMatchSkills,
  OUTCOMES,
} from "@roboref/share";
import { IncidentOutcome, Incident } from "~utils/data/incident";
import {
  useEditIncident,
  useEventDeletedIncidents,
  useIncident,
  useUndeleteIncident,
} from "~utils/hooks/incident";
import { useEventMatchesForTeam, useEventTeam } from "~utils/hooks/robotevents";
import { Rule, useRulesForEvent } from "~utils/hooks/rules";
import { useCurrentEvent } from "~utils/hooks/state";
import { queryClient } from "~utils/data/query";
import { KeyRegister, LWWKeys } from "@roboref/consistency";
import { AssetPicker, AssetPreview } from "~components/Assets";
import { Spinner } from "~components/Spinner";
import { timeAgo } from "~utils/time";
import { usePeerUserName } from "~utils/data/share";
import { LocalAsset, saveLocalAsset } from "~utils/data/assets";
import { ArrowUpTrayIcon, CameraIcon, TrashIcon } from "@heroicons/react/20/solid";
import { twMerge } from "tailwind-merge";

const ENABLE_IMAGE_UPLOAD = true;

const EditIncidentPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku, incidentId } = useParams({ strict: false });
  const id = incidentId ?? "";

  const [incident, setIncident] = useState<Incident>();
  const { mutateAsync: editIncident } = useEditIncident();
  const { mutateAsync: undeleteIncident, isPending: isUndeletePending } =
    useUndeleteIncident();

  const { data: deletedIncidents } = useEventDeletedIncidents(sku);
  const isDeleted = useMemo(
    () => deletedIncidents?.some((i) => i.id === id) ?? false,
    [deletedIncidents, id]
  );

  const { data: incidentData, isLoading } = useIncident(id, { enabled: !!id });
  useEffect(() => {
    if (incidentData) {
      setIncident(incidentData);
    }
  }, [incidentData]);

  const update = useCallback(
    (update: Partial<Pick<Incident, LWWKeys<Incident>>>) => {
      if (!incident) return;

      setIncident((incident) =>
        incident
          ? {
              ...incident,
              ...update,
            }
          : undefined
      );
    },
    [incident]
  );

  const { data: eventData } = useCurrentEvent();
  const { data: teamData } = useEventTeam(eventData, incident?.team);
  const { data: teamMatches } = useEventMatchesForTeam(
    eventData,
    teamData,
    undefined,
    { enabled: !!incident?.team }
  );

  const teamMatchesByDivision = useMemo(() => {
    const divisions: Record<string, MatchData[]> = {};

    if (!teamMatches) return [];

    for (const match of teamMatches) {
      if (divisions[match.division.name]) {
        divisions[match.division.name].push(match);
      } else {
        divisions[match.division.name] = [match];
      }
    }

    return Object.entries(divisions);
  }, [teamMatches]);

  const { data: game } = useRulesForEvent(eventData);

  const onChangeIncidentMatch = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      if (e.target.value === "Skills") {
        update({
          match: {
            type: "skills",
            skillsType: "driver",
            attempt: 1,
          },
        });
        return;
      }

      const [division, name] = e.target.value.split("@");
      const match = teamMatches?.find((match) => {
        return (
          match.division.id === Number.parseInt(division) && match.name === name
        );
      });

      update({
        match: match
          ? {
              type: "match",
              id: match.id,
              name: match.name,
              division: match.division.id,
            }
          : undefined,
      });
    },
    [teamMatches, update]
  );

  const onChangeIncidentSkillsType = useCallback(
    (type: IncidentMatchSkills["skillsType"]) => {
      update({
        match:
          incident?.match?.type === "skills"
            ? { ...incident.match, skillsType: type }
            : incident?.match,
      });
    },
    [update, incident?.match]
  );

  const onChangeIncidentSkillsAttempt = useCallback(
    (attempt: number) => {
      update({
        match:
          incident?.match?.type === "skills"
            ? { ...incident.match, attempt }
            : incident?.match,
      });
    },
    [incident?.match, update]
  );

  const onChangeIncidentOutcome = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      update({
        outcome: e.target.value as IncidentOutcome,
      });
    },
    [update]
  );

  const enrichRules = useCallback(
    (rules: string[]) => {
      const gameRules = game?.ruleGroups.flatMap((group) => group.rules) ?? [];
      return rules
        .map((rule) => gameRules.find((r) => r.rule === rule))
        .filter((x): x is Rule => !!x);
    },
    [game]
  );

  const initialRichRules = useMemo(() => {
    return enrichRules(incident?.rules ?? []);
  }, [enrichRules, incident?.rules]);

  const [incidentRules, setIncidentRules] = useState(initialRichRules);
  useEffect(() => {
    if (initialRichRules) {
      setIncidentRules(initialRichRules);
    }
  }, [initialRichRules]);

  const onChangeIncidentRules = useCallback(
    (rules: Rule[]) => {
      setIncidentRules(rules);
      update({
        rules: rules.map((r) => r.rule),
      });
    },
    [update]
  );

  const onChangeIncidentNotes = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      update({ notes: e.target.value });
    },
    [update]
  );

  const onChangeFlag = useCallback(
    (flag: IncidentFlag, value: boolean) => {
      update({
        flags: value
          ? [...(incident?.flags ?? []), flag]
          : (incident?.flags?.filter((f) => f !== flag) ?? []),
      });
    },
    [incident?.flags, update]
  );

  const onUndelete = useCallback(async () => {
    if (!incident) return;

    try {
      await undeleteIncident(incident);
      toast({ type: "info", message: "Undeleted Note" });

      if (router.history.canGoBack()) {
        router.history.back();
      } else {
        navigate({ to: "/$sku", params: { sku: sku ?? "" } });
      }
    } catch (e) {
      toast({
        type: "error",
        message: "Could not undelete note!",
        context: JSON.stringify(e),
      });
    }
  }, [incident, undeleteIncident, router, navigate, sku]);

  const onPickAsset = useCallback(
    async (asset: LocalAsset) => {
      await saveLocalAsset(asset);
      update({
        assets: [...(incident?.assets ?? []), asset.id],
      });
    },
    [incident?.assets, update]
  );

  const onRemoveAsset = useCallback(
    (assetId: string) => {
      update({
        assets: (incident?.assets ?? []).filter((id) => id !== assetId),
      });
    },
    [incident?.assets, update]
  );

  const onSave = useCallback(async () => {
    if (!incident) return;

    try {
      await editIncident(incident);
      toast({ type: "info", message: "Saved Note" });

      if (router.history.canGoBack()) {
        router.history.back();
      } else {
        navigate({ to: "/$sku", params: { sku: sku ?? "" } });
      }
    } catch (e) {
      toast({
        type: "error",
        message: "Could not save note!",
        context: JSON.stringify(e),
      });
    }
  }, [editIncident, incident, router, navigate, sku]);

  const onViewHistory = useCallback(() => {
    if (incident) {
      queryClient.setQueryData(["incidents", id], incident);
    }
    navigate({
      to: "/$sku/entry/$incidentId/history",
      params: { sku: sku ?? "", incidentId: id },
    });
  }, [incident, id, navigate, sku]);

  const mostRecentRegister = useMemo(() => {
    if (!incident || !incident.consistency) return null;
    let newest: { peer: string; instant: string } | null = null;
    for (const reg of Object.values(incident.consistency)) {
      const r = reg as KeyRegister<Record<string, unknown>, string>;
      if (!r || !r.instant) continue;
      if (
        !newest ||
        new Date(r.instant).getTime() > new Date(newest.instant).getTime()
      ) {
        newest = r;
      }
    }
    return newest;
  }, [incident]);

  const lastEditedUser = usePeerUserName(mostRecentRegister?.peer);

  if (isLoading || !incident) {
    return (
      <div className="max-w-xl h-full w-full mx-auto flex-1 p-4">
        <Spinner show />
      </div>
    );
  }

  return (
    <div className="max-w-xl h-full w-full mx-auto flex-1 overflow-y-auto p-4">
      <header className="mb-4">
        <h1 className="text-xl font-bold">
          <span className="font-mono text-emerald-400">{incident.team}</span>
          {" • "}
          <span>{teamData?.team_name}</span>
        </h1>
      </header>

      <label>
        <p className="mt-2 font-medium">Match</p>
        <Select
          value={
            incident.match?.type === "skills"
              ? "Skills"
              : incident.match
              ? `${incident.match.division}@${incident.match.name}`
              : "-1"
          }
          onChange={onChangeIncidentMatch}
          className="max-w-full w-full mt-1"
        >
          <option value="-1">None</option>
          <option value="Skills">Skills</option>
          {teamMatchesByDivision.map(([name, matches]) => (
            <optgroup label={name} key={name}>
              {matches.map((match) => (
                <option
                  value={`${match.division.id}@${match.name}`}
                  key={match.id}
                >
                  {match.name}
                </option>
              ))}
            </optgroup>
          ))}
        </Select>
      </label>

      {incident.match?.type === "skills" ? (
        <div className="flex gap-2 mt-2">
          <Radio
            name="skillsType"
            label="Driver"
            bind={{
              value: incident.match.skillsType,
              onChange: onChangeIncidentSkillsType,
              variant: "driver",
            }}
          />
          <Radio
            name="skillsType"
            label="Auto"
            bind={{
              value: incident.match.skillsType,
              onChange: onChangeIncidentSkillsType,
              variant: "programming",
            }}
          />
          <Radio
            name="skillsAttempt"
            label="1"
            className="flex-1 ml-4"
            bind={{
              value: incident.match.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 1,
            }}
          />
          <Radio
            name="skillsAttempt"
            label="2"
            className="flex-1"
            bind={{
              value: incident.match.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 2,
            }}
          />
          <Radio
            name="skillsAttempt"
            label="3"
            className="flex-1"
            bind={{
              value: incident.match.attempt,
              onChange: onChangeIncidentSkillsAttempt,
              variant: 3,
            }}
          />
        </div>
      ) : null}

      <label>
        <p className="mt-4 font-medium">Outcome</p>
        <Select
          value={incident.outcome}
          onChange={onChangeIncidentOutcome}
          className="max-w-full w-full mt-1"
        >
          {OUTCOMES.map((outcome) => (
            <option key={outcome} value={outcome}>
              {outcome}
            </option>
          ))}
        </Select>
      </label>

      <div>
        <p className="mt-4 font-medium">Associated Rules</p>
        <RulesMultiSelect
          game={game!}
          value={incidentRules}
          onChange={onChangeIncidentRules}
        />
      </div>

      <div>
        <p className="mt-4 font-medium">Images</p>
        {incident.assets && incident.assets.length > 0 && (
          <section className="grid grid-cols-4 gap-2 mt-2">
            {incident.assets.map((assetId) => (
              <div className="relative" key={assetId}>
                <IconButton
                  className="absolute top-0 right-0 p-2 rounded-none rounded-bl-md rounded-tr-md bg-red-500 z-20"
                  icon={<TrashIcon height={16} />}
                  onClick={() => onRemoveAsset(assetId)}
                />
                <AssetPreview
                  key={assetId}
                  asset={assetId}
                  owner={incident.consistency?.outcome?.peer}
                  uploadedAt={incident.time}
                />
              </div>
            ))}
          </section>
        )}
        <div className="flex gap-3 mt-4">
          <label
            className={twMerge(
              "flex-1 bg-zinc-700 rounded-md flex gap-2 items-center justify-center active:bg-zinc-800 focus-within:bg-zinc-800 focus-within:ring-2 ring-zinc-200 cursor-pointer px-3 py-2",
              !ENABLE_IMAGE_UPLOAD && "opacity-50 cursor-not-allowed"
            )}
            aria-disabled={!ENABLE_IMAGE_UPLOAD}
          >
            <CameraIcon className="w-6 h-6 text-zinc-50" />
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
              "flex-1 bg-zinc-700 rounded-md flex gap-2 items-center justify-center active:bg-zinc-800 focus-within:bg-zinc-800 focus-within:ring-2 ring-zinc-200 cursor-pointer px-3 py-2",
              !ENABLE_IMAGE_UPLOAD && "opacity-50 cursor-not-allowed"
            )}
            aria-disabled={!ENABLE_IMAGE_UPLOAD}
          >
            <ArrowUpTrayIcon className="w-6 h-6 text-zinc-50" />
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

      <div className="mt-6 mb-8">
        {isDeleted ? (
          <div className="flex gap-4">
            <Button
              mode="primary"
              className="flex-1 text-center"
              disabled={isUndeletePending}
              onClick={onUndelete}
            >
              Undelete Note
            </Button>
            <Button
              mode="primary"
              className="flex-1 text-center"
              onClick={onSave}
            >
              Save Changes
            </Button>
          </div>
        ) : (
          <Button
            mode="primary"
            className="w-full text-center"
            onClick={onSave}
          >
            Save Changes
          </Button>
        )}
        <Button
          mode="normal"
          className="w-full text-center mt-3"
          onClick={onViewHistory}
        >
          View Note History
        </Button>
        {mostRecentRegister && (
          <p className="text-center text-xs text-zinc-400 mt-2">
            Last edited {lastEditedUser ? `by ${lastEditedUser}, ` : ""}
            {timeAgo(new Date(mostRecentRegister.instant))}
          </p>
        )}
      </div>
    </div>
  );
};

export const Route = createFileRoute("/$sku/entry/$incidentId/")({
  component: EditIncidentPage,
});
