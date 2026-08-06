import {
  ErrorBoundary as SentryErrorBoundary,
  ErrorBoundaryProps,
  FallbackRender,
} from "@sentry/react";
import { LinkButton, Button } from "./Button";
import { clearCache } from "~utils/data/cache";

function isChunkLoadError(err: unknown): boolean {
  if (!err) return false;
  const msg =
    typeof err === "string"
      ? err
      : (err as { message?: string }).message || String(err);
  const s = msg.toLowerCase();
  return (
    s.includes("failed to load module script") ||
    s.includes("expected a javascript-or-wasm module script") ||
    s.includes("mime type") ||
    s.includes("dynamically imported module") ||
    s.includes("failed to fetch") ||
    s.includes("chunkloaderror") ||
    s.includes("loading chunk")
  );
}

export const ErrorContactDevFallback: FallbackRender = (props) => {
  const isChunkError = isChunkLoadError(props.error);

  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 p-6 flex flex-col items-center justify-center text-center">
      <h2 className="text-xl font-bold text-red-400 mb-2">
        {isChunkError ? "App Update Available" : "An Error Occurred"}
      </h2>
      <p className="text-zinc-400 text-sm mb-6">
        {isChunkError
          ? "A new version of RoboRef has been deployed. Please refresh to load the latest update."
          : "RoboRef encountered an unexpected error. You can get in touch with the developer or reload the app."}
      </p>
      <div className="grid grid-cols-2 gap-3 w-full max-w-sm">
        <LinkButton
          to="/contact"
          className="w-full text-center whitespace-nowrap bg-emerald-600 active:bg-emerald-700 text-white flex items-center justify-center"
        >
          Contact Developer
        </LinkButton>
        <Button
          mode="primary"
          className="w-full text-center whitespace-nowrap flex items-center justify-center"
          onClick={() => {
            props.resetError();
            clearCache();
          }}
        >
          {isChunkError ? "Update App" : "Reload App"}
        </Button>
      </div>
    </main>
  );
};

export const ErrorBoundary: React.FC<ErrorBoundaryProps> = (props) => (
  <SentryErrorBoundary
    fallback={(props) => <ErrorContactDevFallback {...props} />}
  >
    {props.children}
  </SentryErrorBoundary>
);
