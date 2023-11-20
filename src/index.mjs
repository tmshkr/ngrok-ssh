import { execSync } from "child_process";
import { ACTION_PATH } from "./env.mjs";

const action = process.argv[2];

switch (action) {
  case "post":
    run(action);
    break;
  case "main":
    run(action);
    break;
  default:
    console.error(`Unknown action: ${action}`);
    process.exit(1);
}

function run(action) {
  try {
    execSync(`${ACTION_PATH}/src/${action}.sh`, {
      env: { ...process.env, ACTION_PATH },
      stdio: "inherit",
    });
  } catch (err) {
    console.error(err.message);
    process.exit(err.status);
  }
}
