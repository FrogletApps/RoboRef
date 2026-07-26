import React, { useCallback, useEffect, useMemo, useState } from "react";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";
import { MatchData } from "@referee-fyi/robotevents";
import { Button } from "~components/Button";
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
} from "@referee-fyi/share";
import { IncidentOutcome, Incident } from "~utils/data/incident";
import {
  useDeleteIncident,
  useEditIncident,
  useIncident,
} from "~utils/hooks/incident";
import { useEventMatchesForTeam, useEventTeam } from "~utils/hooks/robotevents";
import { Rule, useRulesForEvent } from "~utils/hooks/rules";
import { useCurrentEvent } from "~utils/hooks/state";
import { EditHistory } from "~components/EditHistory";
import { LWWKeys } from "@referee-fyi/consistency";
import { AssetPreview } from "~components/Assets";
import { Spinner } from "~components/Spinner";

export const EditIncidentPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku, incidentId } = useParams({ strict: false });
  const id = incidentId ?? "";

  const [incident, setIncident] = useState<Incident>();
  const { mutateAsync: deleteIncident } = useDeleteIncident();
  const { mutateAsync: editIncident } = useEditIncident();

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

  const onDelete = useCallback(async () => {
    if (!incident) return;

    try {
      await deleteIncident(incident.id);
      toast({ type: "info", message: "Deleted Incident" });

      if (router.history.canGoBack()) {
        router.history.back();
      } else {
        navigate({ to: "/$sku", params: { sku: sku ?? "" } });
      }
    } catch (e) {
      toast({
        type: "error",
        message: "Could not delete incident!",
        context: JSON.stringify(e),
      });
    }
  }, [deleteIncident, incident, router, navigate, sku]);

  const onSave = useCallback(async () => {
    if (!incident) return;

    try {
      await editIncident(incident);
      toast({ type: "info", message: "Saved Incident" });

      if (router.history.canGoBack()) {
        router.history.back();
      } else {
        navigate({ to: "/$sku", params: { sku: sku ?? "" } });
      }
    } catch (e) {
      toast({
        type: "error",
        message: "Could not save incident!",
        context: JSON.stringify(e),
      });
    }
  }, [editIncident, incident, router, navigate, sku]);

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
        <div className="grid grid-cols-4 gap-4 mt-2">
          {incident.assets.map((asset) => (
            <AssetPreview key={asset} asset={asset} />
          ))}
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

      <section className="mt-6">
        <h2 className="font-bold text-lg mb-2">Edit History</h2>
        <EditHistory value={incident} valueKey="notes" />
      </section>

      <div className="flex gap-4 mt-6">
        <Button
          mode="dangerous"
          className="flex-1 text-center"
          onClick={onDelete}
        >
          Delete Entry
        </Button>
        <Button
          mode="primary"
          className="flex-1 text-center"
          onClick={onSave}
        >
          Save Changes
        </Button>
      </div>
    </div>
  );
};

export const Route = createFileRoute("/$sku/entry/$incidentId")({
  component: EditIncidentPage,
});
