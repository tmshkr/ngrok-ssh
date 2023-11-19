export const {
  GITHUB_ACTION,
  GITHUB_ACTION_REF,
  GITHUB_ACTION_REPOSITORY,
  GITHUB_WORKSPACE,
} = process.env;

export const actionPath =
  GITHUB_ACTION === "__self"
    ? GITHUB_WORKSPACE
    : `/home/runner/work/_actions/${GITHUB_ACTION_REPOSITORY}/${GITHUB_ACTION_REF}`;
