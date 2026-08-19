import { Client } from "@roboref/vexevents";

const client = Client({ authorization: { token: "abc" } });

async function test() {
  const event = await client.events.getBySKU("RE-VRC-23-3801");
  console.log(event);
}

test();
