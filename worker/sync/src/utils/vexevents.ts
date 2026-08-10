import { Client } from "@roboref/vexevents";
import { Env } from "../types";

export function getVexEventsClient(env: Env) {
  return Client({
    authorization: { token: env.VEX_EVENTS_TOKEN },
    request: { baseUrl: "https://events.vex.com/api/v2" },
  });
}
export const getRobotEventsClient = getVexEventsClient;
