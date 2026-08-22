import { createFileRoute, redirect } from "@tanstack/react-router";
export { getChangeLogHash } from "./changeLog";

export const Route = createFileRoute("/updates")({
  beforeLoad: () => {
    throw redirect({
      to: "/changeLog",
    });
  },
});
