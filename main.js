const { execSync } = require("child_process");

try {
  execSync("./main.sh", { stdio: "inherit" });
} catch (error) {
  console.error(error);
}
