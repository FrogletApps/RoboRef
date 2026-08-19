import { Client, ClientOptions } from "@roboref/vexevents";
import { fetch } from "undici";

async function main() {
  const options: ClientOptions = {
    authorization: {
      token: "YOUR_TOKEN",
    },
  };
  console.log("This is a mock run, actual usage requires a valid token which we don't have");
}
main();
