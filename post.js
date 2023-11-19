const { execSync } = require("child_process");
const actionPath = `/home/runner/work/_actions/tmshkr/ngrok-ssh/dev`;
try {
  execSync(`ACTION_PATH=${actionPath} ${actionPath}/post.sh`, {
    stdio: "inherit",
  });
} catch (error) {
  console.error(err.message);
  process.exit(err.status);
}
