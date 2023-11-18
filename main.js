const { execSync } = require("child_process");

try {
  execSync("./main.sh", { stdio: "inherit" });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
