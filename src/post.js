const { execSync } = require("child_process");
const { resolve, join } = require("path");

const ACTION_PATH = resolve(__dirname, "..");

try {
  execSync(join(ACTION_PATH, "src", `post.sh`), {
    env: { ...process.env, ACTION_PATH },
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
