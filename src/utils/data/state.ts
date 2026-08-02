export function getBuildMode() {
  return import.meta.env.VITE_REFEREE_FYI_BUILD_MODE;
}

export const WORLDS_EVENTS: string[] = [
  "RE-V5RC-24-8909",
  "RE-V5RC-24-8910",
  "RE-VURC-24-8911",
  "RE-V5RC-24-8912",
  "RE-VIQRC-24-8913",
  "RE-VIQRC-24-8914",
];

export function isWorldsBuild() {
  return getBuildMode() === "WC";
}

export function isStandardBuild() {
  return getBuildMode() === "STANDARD";
}

export function isVIQRC(sku?: string | null): boolean {
  if (!sku) return false;
  const upper = sku.toUpperCase();
  return upper.includes("VIQRC") || upper.includes("VIQC");
}

export function isV5(sku?: string | null): boolean {
  if (!sku) return false;
  const upper = sku.toUpperCase();
  return (
    upper.includes("V5RC") ||
    upper.includes("VRC") ||
    upper.includes("VEXU") ||
    upper.includes("VURC") ||
    upper.includes("VAIRC") ||
    upper.includes("V5")
  );
}

export function getSkuTextColorClass(sku?: string | null): string {
  if (isVIQRC(sku)) {
    return "text-blue-400";
  }
  if (isV5(sku)) {
    return "text-red-400";
  }
  return "text-emerald-400";
}

export function getSkuBgColorClass(sku?: string | null): string {
  if (isVIQRC(sku)) {
    return "bg-blue-400";
  }
  if (isV5(sku)) {
    return "bg-red-400";
  }
  return "bg-emerald-400";
}

export type AppEnvironment = "local" | "test" | "production";

export function getAppEnvironment(): AppEnvironment {
  if (typeof window === "undefined") {
    return "production";
  }

  const hostname = window.location.hostname;

  const isLocalHost =
    import.meta.env.DEV ||
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname === "0.0.0.0" ||
    hostname === "::1" ||
    hostname === "[::1]" ||
    hostname.endsWith(".local") ||
    hostname.startsWith("127.") ||
    hostname.startsWith("192.168.") ||
    hostname.startsWith("10.") ||
    /^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(hostname);

  if (isLocalHost) {
    return "local";
  }

  const shareServer =
    (import.meta.env.VITE_REFEREE_FYI_SHARE_SERVER as string | undefined) ?? "";
  const isTest =
    hostname.includes("test") ||
    shareServer.includes("test") ||
    import.meta.env.MODE === "test" ||
    import.meta.env.VITE_REFEREE_FYI_ENV === "test";

  if (isTest) {
    return "test";
  }

  return "production";
}

