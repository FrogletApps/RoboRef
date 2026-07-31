import { createFileRoute, Outlet } from "@tanstack/react-router";

export const Route = createFileRoute("/$sku/entry/$incidentId")({
  component: () => <Outlet />,
});
