const { execSync } = require("child_process");

try {
  execSync(`${process.env.GITHUB_WORKSPACE}/post.sh`, { stdio: "inherit" });
} catch (error) {
  console.error(err.message);
  process.exit(err.status);
}
