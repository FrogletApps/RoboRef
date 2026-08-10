/// <reference types="vite/client" />

declare const __ROBOREF_VERSION__: string;

interface ImportMetaEnv {
  readonly VITE_ROBOREF_SHARE_SERVER: string;
  readonly VITE_ROBOREF_BUILD_MODE: "WC" | "STANDARD";
  readonly VITE_ROBOREF_ENABLE_SENTRY: boolean | string;
  readonly VITE_SENTRY_DSN: string;
}

declare module "*.md" {
  import React from "react";
  const MDXComponent: (props: any) => React.ReactElement | null;
  export default MDXComponent;
}

declare module "*.mdx" {
  import React from "react";
  const MDXComponent: (props: any) => React.ReactElement | null;
  export default MDXComponent;
}

declare module "*.md?raw" {
  const content: string;
  export default content;
}

