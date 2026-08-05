import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Button } from "~components/Button";
import { logger } from "@sentry/react";

const ContactPage: React.FC = () => {
  const [shouldError, setShouldError] = useState(false);

  if (shouldError) {
    throw new Error("Previewing error screen");
  }

  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto">
      <section className="mt-4">
        <p className="text-zinc-300">
          If you want to get in touch please email us at{" "}
          <a
            className="text-emerald-400 underline"
            href={`mailto:hello@roboref.fyi?subject=${encodeURIComponent(
              `RoboRef Version ${__ROBOREF_VERSION__}`
            )}`}
          >
            hello@roboref.fyi
          </a>
          .
        </p>
        <br />
        <p className="text-zinc-400">
          For bug reports please include as much information as possible, for example what you were trying to do in the app, what happened, when it happened, and what event you're at. If possible include screenshots to help us see what's happening.
        </p>
        {import.meta.env.DEV ? (
          <div className="mt-4 flex flex-col gap-2">
            <Button
              mode="dangerous"
              onClick={() => {
                setShouldError(true);
              }}
            >
              Preview Error Screen
            </Button>
            <Button
              mode="normal"
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
          </div>
        ) : null}
      </section>
    </main>
  );
};

export const Route = createFileRoute("/contact")({
  component: ContactPage,
});
