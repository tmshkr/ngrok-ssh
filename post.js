const { execSync } = require("child_process");

try {
  execSync("./post.sh", { stdio: "inherit" });
} catch (error) {
  console.error(err.message);
  process.exit(err.status);
}
