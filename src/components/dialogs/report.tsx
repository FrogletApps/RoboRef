import { Dialog, DialogBody, DialogHeader } from "~components/Dialog";
import { ErrorReport } from "~utils/data/report";
import { Button } from "~components/Button";
import { logger } from "@sentry/react";

export type ReportIssueDialogProps = {
  open: boolean;
  setOpen: (value: boolean) => void;
  comment?: string;
  context?: string;
  error?: ErrorReport;
};

export const ReportIssueDialog: React.FC<ReportIssueDialogProps> = ({
  open,
  setOpen,
}) => {
  return (
    <Dialog
      mode="modal"
      open={open}
      onClose={() => setOpen(false)}
      aria-label="Report Issues with RoboRef"
    >
      <DialogHeader
        onClose={() => setOpen(false)}
        title="Report Issues with RoboRef"
      />
      <DialogBody className="px-2">
        <p>
          If you want to get in touch please contact the developer at{" "}
          <a
            className="text-emerald-400 underline"
            href={`mailto:frogletapps+roboref_bug@outlook.com?subject=${encodeURIComponent(
              `RoboRef Bug Report ${__ROBOREF_VERSION__}`
            )}`}
          >
            frogletapps+roboref_bug@outlook.com
          </a>
          .
        </p>
        {import.meta.env.DEV ? (
          <Button
            mode="dangerous"
            className="mt-4"
            onClick={() => {
              // Send a log before throwing, to verify Sentry's log + error
              // capture. The throw happens in an event handler, so it is NOT
              // caught by the React ErrorBoundary — Sentry's global handler
              // reports it instead. Dev-only: never shipped to real users.
              logger.info("User triggered test error", {
                action: "test_error_button_click",
              });
              throw new Error("This is your first error!");
            }}
          >
            Fire a test error to Sentry
          </Button>
        ) : null}
      </DialogBody>
    </Dialog>
  );
};