import { useEffect, useMemo, useState } from "react";
import { EventData } from "@roboref/vexevents";
import {
  Button,
  ExternalLinkButton,
  IconButton,
  LinkButton,
} from "~components/Button";
import {
  forceEventInvitationSync,
  getInstancesForEvent,
  getIntegrationAPIEndpoints,
  removeInvitation,
} from "~utils/data/share";
import {
  ArrowUpRightIcon,
  FlagIcon,
  UserCircleIcon,
  UserPlusIcon,
} from "@heroicons/react/20/solid";
import { Dialog, DialogBody } from "~components/Dialog";
import {
  useCreateInstance,
  useEventInvitation,
  useIntegrationAPIDeleteIncident,
  useIntegrationAPIIncidents,
  useIntegrationAPIUsers,
  useIntegrationBearer,
  useSystemKeyIntegrationBearer,
} from "~utils/hooks/share";
import { Input } from "~components/Input";
import { toast } from "~components/Toast";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Warning } from "~components/Warning";
import { Spinner } from "~components/Spinner";
import { useEventIncidents } from "~utils/hooks/incident";
import { TrashIcon } from "@heroicons/react/24/outline";
import { queryClient } from "~utils/data/query";
import { ReadyState, useShareConnection } from "~models/ShareConnection";
import { ClickToCopy, ClickToCopyIcon } from "~components/ClickToCopy";
import { twMerge } from "tailwind-merge";
import { tryPersistStorage } from "~utils/data/keyval";
import { UpdatePrompt } from "~components/UpdatePrompt";
import { InvitationListItem } from "@roboref/share";
import { isWorldsBuild, WORLDS_EVENTS } from "~utils/data/state";
import { Incident } from "~components/Incident";
import {
  useHiddenEvents,
  useHideEvent,
  useUnhideEvent,
} from "~utils/hooks/history";

export type ManageDialogProps = {
  open: boolean;
  onClose: () => void;
  sku: string;
};



export const LeaveDialog: React.FC<ManageDialogProps> = ({
  open,
  onClose,
  sku,
}) => {
  const { data: invitation } = useEventInvitation(sku);

  const { forceSync, disconnect, invitations } = useShareConnection([
    "forceSync",
    "disconnect",
    "invitations",
  ]);

  const { mutateAsync: onClickLeave } = useMutation({
    mutationFn: async () => {
      await disconnect();
      await removeInvitation(sku);
      queryClient.invalidateQueries({ queryKey: ["event_invitation_all"] });
      onClose();
      forceSync();
    },
  });

  return (
    <Dialog
      mode="modal"
      open={open}
      className="p-4"
      onClose={onClose}
      aria-label="Leave share instance"
    >
      <DialogBody>
        <p>
          Are you sure? If you leave, you will need an admin to invite you
          again.
        </p>
        {invitation?.admin && invitations.filter((i) => i.admin).length < 2 ? (
          <Warning
            className="mt-4"
            message="Since you are the last admin, leaving will end this instance and remove all other users."
          />
        ) : null}
        <Button
          mode="dangerous"
          className="mt-4"
          onClick={() => onClickLeave()}
        >
          Leave
        </Button>
        <Button mode="normal" className="mt-4" onClick={onClose}>
          Stay
        </Button>
      </DialogBody>
    </Dialog>
  );
};

export const ProfilePrompt: React.FC = () => {
  const {
    profile: { name },
    updateProfile,
  } = useShareConnection(["profile", "updateProfile"]);

  const [localName, setLocalName] = useState("");
  useEffect(() => {
    if (name) {
      setLocalName(name);
    }
  }, [name]);

  // Save
  const { mutate: setNameContinue, isPending: isPendingSetNameContinue } =
    useMutation({
      mutationFn: () => updateProfile({ name: localName }),
    });

  return (
    <>
      <label>
        <h1 className="font-bold mt-4">Display Name</h1>
        <p className="text-zinc-400 text-sm mb-2">
          Your display name when sharing and logging incidents
        </p>
        <Input
          className="w-full"
          value={localName}
          onChange={(e) => setLocalName(e.currentTarget.value.trim())}
        />
      </label>
      <Button
        className={twMerge("mt-4", !localName ? "opacity-50" : "")}
        mode="primary"
        onClick={() => setNameContinue()}
        disabled={!localName}
      >
        Save Name & Enable Sharing
      </Button>
      <Spinner show={isPendingSetNameContinue} />
    </>
  );
};

export type InstanceUserListItemProps = {
  user: InvitationListItem;
  active: boolean;
};

export const InstanceUserListItem: React.FC<InstanceUserListItemProps> = ({
  user,
  active,
}) => {
  return (
    <div className="flex gap-2 items-center flex-1">
      <UserCircleIcon height={24} />
      <p>{user.user.name}</p>
      {user.admin ? (
        <span className="text-xs  bg-purple-600 px-2 py-0.5 rounded-md">
          Admin
        </span>
      ) : null}
      {active ? (
        <span className="text-xs  bg-emerald-600 px-2 py-0.5 rounded-md">
          Connected
        </span>
      ) : (
        <span className="text-xs  bg-zinc-700 px-2 py-0.5 rounded-md">
          Offline
        </span>
      )}
    </div>
  );
};

export const ShareManager: React.FC<ManageTabProps> = ({ event }) => {
  // Dialogs
  const [leaveDialogOpen, setLeaveDialogOpen] = useState(false);

  // Instance State
  const { data: invitation } = useEventInvitation(event.sku);
  const connection = useShareConnection([
    "profile",
    "updateProfile",
    "invitations",
    "activeUsers",
    "readyState",
    "forceSync",
    "disconnect",
  ]);

  // If we are not in the instance, force an invalidation
  useEffect(() => {
    if (!invitation?.accepted) {
      return;
    }

    const instanceInList = connection.invitations.some(
      (inv) => inv.user.key === connection.profile?.key
    );

    if (!instanceInList) {
      forceEventInvitationSync(event.sku);
    }
  }, [invitation, connection.invitations, event.sku, connection.profile?.key]);

  const { data: entries } = useEventIncidents(event.sku);
  const isSharing = useMemo(
    () => !!invitation && invitation.accepted,
    [invitation]
  );

  // Remove User
  const { mutateAsync: removeUser, isPending: isPendingRemoveUser } =
    useMutation({
      mutationFn: async (user: string) => {
        await removeInvitation(event.sku, user);
        queryClient.invalidateQueries({ queryKey: ["event_invitation_all"] });
        return connection.forceSync();
      },
    });

  // Begin Sharing
  const { mutateAsync: createInstance } = useCreateInstance(event.sku);
  const {
    mutateAsync: onClickBeginSharing,
    isPending: isCreateInstancePending,
  } = useMutation({
    mutationFn: async () => {
      await tryPersistStorage();
      await connection.updateProfile(connection.profile);
      const response = await createInstance();

      if (response.success) {
        toast({ type: "info", message: "Sharing!" });
      } else {
        toast({
          type: "error",
          message: response.details,
          context: JSON.stringify(response),
        });
      }
    },
  });

  if (!connection.profile.name) {
    return (
      <section className="mt-4">
        <h2 className="font-bold">Sharing</h2>
        <p className="text-zinc-400 text-sm mb-2">
          You must set your display name below to set up sharing
        </p>
        <ProfilePrompt />
      </section>
    );
  }

  const showSpinner =
    (connection.readyState !== ReadyState.Closed &&
      connection.readyState !== ReadyState.Open) ||
    isPendingRemoveUser ||
    isCreateInstancePending ||
    (invitation?.accepted && connection.readyState !== ReadyState.Open);

  return (
    <section className="mt-4">
      <LeaveDialog
        sku={event.sku}
        open={leaveDialogOpen}
        onClose={() => setLeaveDialogOpen(false)}
      />

      <h2 className="font-bold">Sharing</h2>
      <p className="text-zinc-400 text-sm">Share Name: {connection.profile.name}</p>
      <p className="text-zinc-400 text-sm">You can change your share name in the settings.</p>
      {isSharing ? (
        <div className="mt-2">
          {invitation?.admin ? (
            <LinkButton
              to="/$sku/invite"
              params={{ sku: event.sku }}
              className="flex gap-2 items-center justify-center"
            >
              <UserPlusIcon height={20} />
              <p>Invite</p>
            </LinkButton>
          ) : null}
          <Button
            mode="dangerous"
            className="mt-2"
            onClick={() => setLeaveDialogOpen(true)}
          >
            Leave
          </Button>
          <nav className="flex gap-2 justify-evenly mt-4">
            <p className="text-lg">
              <FlagIcon height={20} className="inline mr-2" />
              <span className="text-zinc-400">
                {entries?.length ?? 0} entries
              </span>
            </p>
            <p className="text-lg">
              <UserCircleIcon height={20} className="inline mr-2" />
              <span className="text-zinc-400">
                {connection.activeUsers.length} active
              </span>
            </p>
          </nav>
          <Spinner show={showSpinner} />
          <ul className="mt-4">
            {connection.invitations.map((user) => (
              <li
                key={user.user.key}
                className="py-2 px-4 rounded-md mt-2 flex"
              >
                <InstanceUserListItem
                  user={user}
                  active={connection.activeUsers.some(
                    (u) => u.key === user.user.key
                  )}
                />
                {invitation?.admin && !user.admin ? (
                  <IconButton
                    icon={<TrashIcon height={20} />}
                    onClick={() => removeUser(user.user.key)}
                    className="bg-transparent"
                  />
                ) : null}
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {!isSharing ? (
        <section className="mt-2">
          <p className="text-zinc-400 text-sm">
            Create or join a sharing instance to synchronize the anomaly log between devices.
          </p>
          {isWorldsBuild() && WORLDS_EVENTS.includes(event.sku) ? (
            <p className="mt-2 text-zinc-400 text-sm">
              New instances cannot be created for this event. Please reach out
              to your group area supervisor to get access to the existing Worlds
              instances.
            </p>
          ) : (
            <Button
              mode="primary"
              className="mt-2"
              disabled={!connection.profile.name}
              onClick={() => onClickBeginSharing()}
            >
              Begin Sharing
            </Button>
          )}
          <LinkButton
            to="/$sku/join"
            params={{ sku: event.sku }}
            className="w-full text-center mt-2"
          >
            Join Existing
          </LinkButton>
          <Spinner show={showSpinner} />
        </section>
      ) : null}
    </section>
  );
};

const NoteSummaryLink: React.FC<ManageTabProps> = ({ event }) => {
  return (
    <section className="mt-4">
      <h2 className="font-bold">Note Summary</h2>
      <p className="text-zinc-400 text-sm">See a summary of all notes submitted during the event.</p>
      <LinkButton
        to="/$sku/summary"
        params={{ sku: event.sku }}
        className="w-full text-center mt-2"
      >
        Note Summary
      </LinkButton>
    </section>
  );
};

const IntegrationInfo: React.FC<ManageTabProps> = ({ event }) => {
  const { data: bearerToken, isSuccess: isSuccessBearerToken } =
    useIntegrationBearer(event.sku);

  const { json, csv, pdf } = useMemo(() => {
    if (!bearerToken) {
      return { json: "", csv: "", pdf: "" };
    }
    return getIntegrationAPIEndpoints(event.sku, { token: bearerToken });
  }, [bearerToken, event.sku]);

  if (!isSuccessBearerToken || !bearerToken) {
    return null;
  }

  return (
    <section className="mt-4">
      <h2 className="font-bold">Reports & Data Export</h2>
      <p className="text-zinc-400 text-sm">
        Use these URLs to give others up-to-date read-only access to
        the anomaly log for this instance.{" "}
        <em>
          Anyone who has this URL can pull this data at any time, so treat these
          carefully!
        </em>
      </p>
      <ClickToCopy prefix="PDF" message={pdf.toString()} className="flex-1" />
      <ClickToCopy prefix="CSV" message={csv.toString()} className="flex-1" />
      <ClickToCopy prefix="JSON" message={json.toString()} className="flex-1" />
      <ClickToCopy prefix="BEARER" message={bearerToken} className="flex-1" />
    </section>
  );
};

type SystemKeyIntegrationInfoProps = ManageTabProps & {
  instance: string;
};

const SystemKeyIntegrationInfo: React.FC<SystemKeyIntegrationInfoProps> = ({
  event,
  instance,
}) => {
  const { data: bearerToken, isPending: isPendingSystemKeyIntegrationBearer } =
    useSystemKeyIntegrationBearer(event.sku, instance);

  const credentials = {
    token: bearerToken ?? "",
    instance,
  };

  const { mutate: deleteIncident, isPending: isPendingDeleteIncident } =
    useIntegrationAPIDeleteIncident(event.sku, credentials);

  const { json, csv, pdf } = useMemo(() => {
    if (!bearerToken) {
      return { json: "", csv: "", pdf: "" };
    }
    return getIntegrationAPIEndpoints(event.sku, {
      token: bearerToken,
      instance,
    });
  }, [bearerToken, event.sku, instance]);

  const { data: incidents, isPending: isPendingIntegrationAPIIncidents } =
    useIntegrationAPIIncidents(event.sku, credentials, {
      enabled: !!bearerToken,
    });

  const { data: users, isPending: isPendingIntegrationAPIUsers } =
    useIntegrationAPIUsers(event.sku, credentials, { enabled: !!bearerToken });

  const isPending =
    isPendingSystemKeyIntegrationBearer ||
    isPendingIntegrationAPIIncidents ||
    isPendingIntegrationAPIUsers;

  return (
    <div className="mt-4 bg-zinc-900 p-4 rounded-md">
      <h1 className="font-mono flex items-center gap-2 justify-center">
        <span className="text-ellipsis overflow-hidden text-nowrap whitespace-nowrap flex-1">
          {instance}
        </span>
        <ClickToCopyIcon value={instance} className="mt-0" />
      </h1>
      <nav className="flex gap-2 justify-evenly mt-4">
        <p className="text-lg">
          <FlagIcon height={20} className="inline mr-2" />
          <span className="text-zinc-400">
            {incidents?.length ?? 0} entries
          </span>
        </p>
        <p className="text-lg">
          <UserCircleIcon height={20} className="inline mr-2" />
          <span className="text-zinc-400">{users?.active.length} active</span>
        </p>
      </nav>
      <Spinner show={isPending} />
      <ul className="mt-4">
        {users?.invitations.map((user) => (
          <li key={user.user.key} className="py-2 px-4 rounded-md mt-2 flex">
            <InstanceUserListItem
              user={user}
              active={users.active.some((u) => u.key === user.user.key)}
            />
          </li>
        ))}
      </ul>
      <div className="flex mt-4 gap-2">
        <ExternalLinkButton
          href={json.toString()}
          className="flex-1 text-center flex items-center gap-4 justify-between"
        >
          JSON
          <ArrowUpRightIcon height={16} className="text-emerald-400" />
        </ExternalLinkButton>
        <ExternalLinkButton
          href={csv.toString()}
          className="flex-1 text-center flex items-center gap-4 justify-between"
        >
          CSV
          <ArrowUpRightIcon height={16} className="text-emerald-400" />
        </ExternalLinkButton>
        <ExternalLinkButton
          href={pdf.toString()}
          className="flex-1 text-center flex items-center gap-4 justify-between"
        >
          PDF
          <ArrowUpRightIcon height={16} className="text-emerald-400" />
        </ExternalLinkButton>
      </div>
      <details className="mt-4 p-2">
        <summary>
          <span className="ml-2">{incidents?.length} Incidents</span>
        </summary>
        <Spinner show={isPendingDeleteIncident} />
        {incidents?.map((incident) => (
          <div className="flex gap-4 items-center" key={incident.id}>
            <Incident
              key={incident.id}
              incident={incident}
              readonly
              className="flex-1"
            />
            <IconButton
              icon={<TrashIcon height={20} />}
              className="bg-transparent"
              onClick={() => deleteIncident(incident.id)}
            />
          </div>
        ))}
      </details>
    </div>
  );
};

const SystemKeyInfo: React.FC<ManageTabProps> = ({ event }) => {
  const {
    userMetadata: { isSystemKey },
  } = useShareConnection(["userMetadata"]);

  const { data: response, isLoading } = useQuery({
    queryKey: ["@roboref", "get_instance_list", event.sku],
    queryFn: () => getInstancesForEvent(event.sku),
    enabled: isSystemKey,
  });

  const instances = useMemo(() => {
    return response?.success ? response.data.instances : [];
  }, [response]);

  if (!isSystemKey) {
    return null;
  }

  if (isLoading) {
    return <Spinner show />;
  }

  return (
    <section className="mt-4">
      <h2 className="font-bold">Instance List ({instances.length})</h2>
      {instances.map((instance) => (
        <SystemKeyIntegrationInfo
          key={instance}
          event={event}
          instance={instance}
        />
      ))}
    </section>
  );
};

export type ManageTabProps = {
  event: EventData;
};

const HideEventSection: React.FC<ManageTabProps> = ({ event }) => {
  const { data: invitation } = useEventInvitation(event.sku);
  const isSharing = !!invitation && invitation.accepted;

  const { data: hiddenEvents = [] } = useHiddenEvents();
  const isHidden = hiddenEvents.includes(event.sku);
  const { mutate: hideEvent } = useHideEvent();
  const { mutate: unhideEvent } = useUnhideEvent();

  return (
    <section className="mt-4">
      <h2 className="font-bold">Hide Event</h2>
      <p className="text-zinc-400 text-sm">
        {isSharing
          ? "You cannot hide an event while sharing"
          : isHidden
          ? "This event is currently hidden from the main page. To re-add it tap Unhide Event, or search it from the RoboRef home screen."
          : "Hide this event from the list on the main page. Incident data will not be deleted."}
      </p>
      {isHidden ? (
        <Button
          mode="normal"
          className="w-full mt-2 disabled:opacity-50 disabled:cursor-not-allowed"
          onClick={() => unhideEvent(event.sku)}
          disabled={isSharing}
        >
          Unhide Event
        </Button>
      ) : (
        <Button
          mode="dangerous"
          className="w-full mt-2 disabled:opacity-50 disabled:cursor-not-allowed"
          onClick={() => hideEvent(event.sku)}
          disabled={isSharing}
        >
          Hide Event
        </Button>
      )}
    </section>
  );
};

export const EventManageTab: React.FC<ManageTabProps> = ({ event }) => {
  return (
    <section className="max-w-xl max-h-full w-full mx-auto flex-1 mb-12 overflow-y-auto">
      <UpdatePrompt />
      <ShareManager event={event} />
      <NoteSummaryLink event={event} />
      <HideEventSection event={event} />
      <IntegrationInfo event={event} />
      <SystemKeyInfo event={event} />
    </section>
  );
};
