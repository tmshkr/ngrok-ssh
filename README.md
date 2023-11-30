# ngrok-ssh

Installs ngrok and opens an SSH tunnel into your GitHub Actions runner.

Useful for debugging builds, previewing your app on a live server, and managing concurrent workflows.

## Inputs/Outputs

The only required input is your [ngrok authtoken](https://dashboard.ngrok.com/get-started/your-authtoken). The action will fetch your public SSH key from the GitHub API by default, and you can also provide a public key as an input.

You can also specify a custom ngrok config file, which will be merged with the [default config file](.ngrok/ngrok.yml). This allows you to run multiple tunnels at once, e.g., for your app's public HTTP port, in addition to SSH.

See [action.yml](action.yml) for more details.

## Example usage

You can use the [example repo](https://github.com/tmshkr/ngrok-ssh-example) as a template to get started.

```yaml
name: ngrok-ssh
on:
  workflow_dispatch:

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: tmshkr/ngrok-ssh@v1.2.1
        with:
          NGROK_AUTHTOKEN: ${{ secrets.NGROK_AUTHTOKEN }}
          NGROK_CONFIG_FILE: "ngrok.yml"
      - run: npm start
```

You should have a long-running process, like a build, web server, or a `sleep` command after the `ngrok-ssh` step, so that the workflow doesn't terminate before you have a chance to connect. You can also set the `WAIT_FOR_CONNECTION` input to true, and the action will wait for you to connect to the tunnel before allowing the workflow to proceed.
