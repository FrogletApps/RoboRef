import {
  BaseWithLWWConsistency,
  KeyRegister,
  LWWKeys,
} from "@referee-fyi/consistency";
import { useMemo, useState } from "react";
import { twMerge } from "tailwind-merge";
import { timeAgo } from "~utils/time";
import { Button } from "./Button";
import { Dialog, DialogBody, DialogHeader } from "./Dialog";
import { UserCircleIcon, ClockIcon } from "@heroicons/react/20/solid";
import { usePeerUserName } from "~utils/data/share";

export type HistoryRecord = {
  key: string;
  prev: unknown;
  to: unknown;
  peer: string;
  instant: string;
};

export type EditHistoryRecordItemProps = {
  record: HistoryRecord;
  render?: (value: unknown) => React.ReactNode;
};

export const EditHistoryRecordItem: React.FC<EditHistoryRecordItemProps> = ({
  record,
  render = (value) => JSON.stringify(value),
}) => {
  const user = usePeerUserName(record.peer);
  const date = new Date(record.instant);

  if (record.key === "deleted") {
    const isDeletedAction = record.to === true;
    return (
      <section className="bg-zinc-700 p-2 rounded-md mb-4 grid gap-2 grid-cols-2">
        <p className="mr-4">
          <UserCircleIcon
            height={20}
            className="inline mr-2"
            aria-hidden="true"
          />
          <span className="sr-only">User: </span>
          {user}
        </p>
        <p>
          <ClockIcon height={20} className="inline mr-2" aria-hidden="true" />
          <span className="sr-only">Time: </span>
          {date.toLocaleTimeString()}
        </p>
        <p className="col-span-2 font-semibold text-emerald-400">
          {isDeletedAction ? "Deleted Note" : "Undeleted Note"}
        </p>
      </section>
    );
  }

  return (
    <section className="bg-zinc-700 p-2 rounded-md mb-4 grid gap-2 grid-cols-2">
      <p className="mr-4">
        <UserCircleIcon
          height={20}
          className="inline mr-2"
          aria-hidden="true"
        />
        <span className="sr-only">User: </span>
        {user}
      </p>
      <p>
        <ClockIcon height={20} className="inline mr-2" aria-hidden="true" />
        <span className="sr-only">Time: </span>
        {date.toLocaleTimeString()}
      </p>
      <p>
        <span>From </span>
        {render(record.prev)}
      </p>
      <p>
        <span>To </span>
        {render(record.to)}
      </p>
    </section>
  );
};

export type EditHistoryDialogProps<
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
> = {
  open: boolean;
  onClose: () => void;
  value: T;
  valueKey?: K;
  render?: (value: T[K]) => React.ReactNode;
};

const EditHistoryDialog = <
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
>({
  open,
  onClose,
  value,
  render,
}: EditHistoryDialogProps<T, K>) => {
  const allRecords = useMemo(() => {
    if (!value || !value.consistency) return [];
    const records: HistoryRecord[] = [];

    for (const [key, register] of Object.entries(value.consistency)) {
      const reg = register as KeyRegister<Record<string, unknown>, string>;
      if (!reg || !reg.history) continue;

      reg.history.forEach((h, i) => {
        const to = reg.history[i + 1]?.prev ?? value[key];
        records.push({
          key,
          prev: h.prev,
          to,
          peer: h.peer,
          instant: h.instant,
        });
      });
    }

    return records.sort(
      (a, b) => new Date(b.instant).getTime() - new Date(a.instant).getTime()
    );
  }, [value]);

  return (
    <Dialog
      mode="modal"
      open={open}
      onClose={onClose}
      aria-label="Edit History"
    >
      <DialogHeader title="Edit History" onClose={onClose} />
      <DialogBody className="p-2">
        {allRecords.length > 0 ? (
          allRecords.map((record) => (
            <EditHistoryRecordItem
              record={record}
              render={render as (value: unknown) => React.ReactNode}
              key={`${record.key}-${record.instant}`}
            />
          ))
        ) : (
          <p className="text-zinc-400 text-center py-4">No edit history yet</p>
        )}
      </DialogBody>
    </Dialog>
  );
};

export type EditHistoryProps<
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
> = {
  value: T | null | undefined;
  valueKey: K;
  dirty?: boolean;
  className?: string;
  render?: (value: T[K]) => React.ReactNode;
};

export const EditHistory = <
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
>({
  value,
  valueKey,
  dirty = false,
  className,
  render,
}: EditHistoryProps<T, K>) => {
  const mostRecentRegister = useMemo(() => {
    if (!value || !value.consistency) return null;
    let newest: { peer: string; instant: string } | null = null;
    for (const reg of Object.values(value.consistency)) {
      const r = reg as KeyRegister<Record<string, unknown>, string>;
      if (!r || !r.instant) continue;
      if (!newest || new Date(r.instant).getTime() > new Date(newest.instant).getTime()) {
        newest = r;
      }
    }
    return newest;
  }, [value]);

  const user = usePeerUserName(mostRecentRegister?.peer);
  const [historyOpen, setHistoryOpen] = useState(false);

  if (!mostRecentRegister || !value) {
    return (
      <div
        className={twMerge(
          "flex items-center justify-between mt-2 h-8",
          className
        )}
      ></div>
    );
  }

  return (
    <div
      className={twMerge("flex items-center justify-between mt-2", className)}
    >
      <p
        className={twMerge(
          "px-2 text-sm ",
          dirty
            ? "text-black italic bg-emerald-400 rounded-md"
            : "text-emerald-400"
        )}
      >
        {user ? `${user}, ` : ""}
        {timeAgo(new Date(mostRecentRegister.instant))}
      </p>
      <EditHistoryDialog
        open={historyOpen}
        onClose={() => setHistoryOpen(false)}
        value={value}
        valueKey={valueKey}
        render={render}
      />
      <Button
        className="flex items-center w-max gap-2 py-1"
        onClick={() => setHistoryOpen(true)}
      >
        <ClockIcon height={20} />
        History
      </Button>
    </div>
  );
};
