import {
  ErrorBoundary as SentryErrorBoundary,
  ErrorBoundaryProps,
  FallbackRender,
} from "@sentry/react";
import { LinkButton, Button } from "./Button";

export const ErrorContactDevFallback: FallbackRender = (props) => {
  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 p-6 flex flex-col items-center justify-center text-center">
      <h2 className="text-xl font-bold text-red-400 mb-2">An Error Occurred</h2>
      <p className="text-zinc-400 text-sm mb-6">
        RoboRef encountered an unexpected error.
        <br />
        You can get in touch with the developer or reload the app.
      </p>
      <div className="grid grid-cols-2 gap-3 w-full max-w-sm">
        <LinkButton
          to="/contact"
          className="w-full text-center whitespace-nowrap bg-emerald-600 active:bg-emerald-700 text-white flex items-center justify-center"
        >
          Contact Developer
        </LinkButton>
        <Button
          mode="normal"
          className="w-full text-center whitespace-nowrap flex items-center justify-center"
          onClick={() => {
            props.resetError();
            window.location.reload();
          }}
        >
          Reload App
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
