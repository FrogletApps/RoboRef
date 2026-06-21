import {
  ErrorBoundary as SentryErrorBoundary,
  ErrorBoundaryProps,
  FallbackRender,
} from "@sentry/react";
import { ContactDevDialog } from "./dialogs/contact";
import { useCallback } from "react";
import { clearCache } from "~utils/sentry";

export const ErrorContactDevDialog: FallbackRender = (props) => {
  const setOpen = useCallback(
    (value: boolean) => {
      if (value) return;

      props.resetError();

      if (navigator.onLine) {
        clearCache();
      } else {
        window.location.reload();
      }
    },
    [props]
  );
  return (
    <ContactDevDialog
      open={true}
      setOpen={setOpen}
      //context={JSON.stringify(props)}
      //error={props}
    />
  );
};

export const ErrorBoundary: React.FC<ErrorBoundaryProps> = (props) => (
  <SentryErrorBoundary
    fallback={(props) => <ErrorContactDevDialog {...props} />}
  >
    {props.children}
  </SentryErrorBoundary>
);
