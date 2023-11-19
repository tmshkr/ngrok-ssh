const { execSync } = require("child_process");

const {
  GITHUB_ACTION,
  GITHUB_ACTION_REF,
  GITHUB_ACTION_REPOSITORY,
  GITHUB_WORKSPACE,
} = process.env;

const actionPath =
  GITHUB_ACTION === "__self"
    ? GITHUB_WORKSPACE
    : `/home/runner/work/_actions/${GITHUB_ACTION_REPOSITORY}/${GITHUB_ACTION_REF}`;

try {
  execSync(`ACTION_PATH=${actionPath} ${actionPath}/main.sh`, {
    stdio: "inherit",
  });
} catch (err) {
  console.error(err.message);
  process.exit(err.status);
}
