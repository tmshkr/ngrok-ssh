import { execSync } from "child_process";
import { ACTION_PATH } from "./env.mjs";

try {
  execSync(`${ACTION_PATH}/main.sh`, {
    env: { ...process.env, ACTION_PATH },
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
