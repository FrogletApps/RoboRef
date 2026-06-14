import { Client } from "@referee-fyi/robotevents";
import { Env } from "../types";

export function getRobotEventsClient(env: Env) {
  return Client({
    authorization: { token: env.ROBOTEVENTS_TOKEN },
    request: { baseUrl: "https://events.vex.com/api/v2" },
  });
}
