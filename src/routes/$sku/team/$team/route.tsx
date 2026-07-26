import { createFileRoute, Outlet } from "@tanstack/react-router";

export const Route = createFileRoute("/$sku/team/$team")({
  component: () => <Outlet />,
});
