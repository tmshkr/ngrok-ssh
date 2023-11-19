const { execSync } = require("child_process");

try {
  execSync(`/home/runner/work/_actions/tmshkr/ngrok-ssh/dev/main.sh`, {
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
