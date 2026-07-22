import { Dialog, DialogBody, DialogHeader } from "~components/Dialog";
import { Button } from "~components/Button";
import { logger } from "@sentry/react";

export type ContactDevDialogProps = {
  open: boolean;
  setOpen: (value: boolean) => void;
};

export const ContactDevDialog: React.FC<ContactDevDialogProps> = ({
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
        title="Contact Developer"
      />
      <DialogBody className="px-2">
        <p>
          If you want to get in touch please contact the developer at{" "}
          <a
            className="text-emerald-400 underline"
            href={`mailto:frogletapps+roboref_bug@outlook.com?subject=${encodeURIComponent(
              `RoboRef Version ${__ROBOREF_VERSION__}`
            )}`}
          >
            frogletapps+roboref_bug@outlook.com
          </a>
          .
        </p>
        <br></br>
        <p>
          For bug reports please include as much information as possible, for example what you were trying to do in the app. If possible include screenshots to help us see what's happening.
        </p>
        {import.meta.env.DEV ? (
          <Button
            mode="dangerous"
            className="mt-4"
            onClick={() => {
              // Send a log before throwing, to verify Sentry's log + error capture.  
              // Dev-only: never shown to real users.
              logger.info("User triggered test error", {
                action: "test_error_button_click",
              });
              throw new Error("This is a test error!");
            }}
          >
            Fire a test error to Sentry
          </Button>
        ) : null}
      </DialogBody>
    </Dialog>
  );
};