import * as core from "@actions/core";
import { execSync } from "child_process";
import { resolve, join } from "path";

const ACTION_PATH = resolve(__dirname, "..");
const stage = process.argv[2] || core.getState("next_stage") || "main";

switch (stage) {
  case "main":
    core.saveState("next_stage", "post");
    run(stage);
    break;
  case "post":
    core.saveState("next_stage", null);
    run(stage);
    break;
  default:
    console.error(`Unknown stage: ${stage}`);
    process.exit(1);
}

function run(stage) {
  try {
    execSync(join(ACTION_PATH, "src", `${stage}.sh`), {
      env: { ...process.env, ACTION_PATH },
      stdio: "inherit",
    });
  } catch (err) {
    console.error(err.message);
    process.exit(err.status);
  }
}
