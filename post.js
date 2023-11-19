const { execSync } = require("child_process");

try {
  execSync(`/home/runner/work/_actions/tmshkr/ngrok-ssh/dev/post.sh`, {
    stdio: "inherit",
  });
} catch (error) {
  console.error(err.message);
  process.exit(err.status);
}
