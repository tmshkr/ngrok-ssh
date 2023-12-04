#!/bin/env node

const { exec } = require("child_process");
const {
  GH_TOKEN,
  NGROK_TUNNELS,
  SSH_HOSTNAME,
  SSH_USER,
  SSH_PORT,
  SSH_HOST_PUBLIC_KEY,
  REF,
} = process.env;

exec(
  `curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/tmshkr/ngrok-ssh/actions/workflows/test-client.yml/dispatches \
    -d '${JSON.stringify({
      ref: REF,
      inputs: {
        NGROK_TUNNELS,
        SSH_HOSTNAME,
        SSH_USER,
        SSH_PORT,
        SSH_HOST_PUBLIC_KEY,
      },
    })}'
`,
  (err, stdout, stderr) => {
    console.log(stdout);
    console.log(stderr);
    if (err) {
      throw err;
    }
  }
);
