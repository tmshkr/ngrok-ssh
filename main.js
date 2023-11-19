const { execSync } = require("child_process");

try {
  execSync(`${process.env.GITHUB_WORKSPACE}/main.sh`, { stdio: "inherit" });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
