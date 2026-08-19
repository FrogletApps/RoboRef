import { Client } from "@roboref/vexevents";

const client = Client({ authorization: { token: "123" } });

async function test() {
  const e = await client.events.search();
  console.log(e);
}
test();
