import { execSync } from "child_process";
import { actionPath } from "./env.mjs";

try {
  execSync(`ACTION_PATH=${actionPath} ${actionPath}/main.sh`, {
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
