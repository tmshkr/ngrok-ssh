import { execSync } from "child_process";
import { actionPath } from "./env.mjs";

try {
  execSync(`ACTION_PATH=${actionPath} ${actionPath}/post.sh`, {
    stdio: "inherit",
  });
} catch (error) {
  console.error(err.message);
  process.exit(err.status);
}
