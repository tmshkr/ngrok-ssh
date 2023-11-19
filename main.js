const { execSync } = require("child_process");
const actionPath = `/home/runner/work/_actions/tmshkr/ngrok-ssh/dev`;
try {
  execSync(`ACTION_PATH=${actionPath} ${actionPath}/main.sh`, {
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
