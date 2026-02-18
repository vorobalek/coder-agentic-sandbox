# coder-agentic-sandbox

Docker image based on `codercom/enterprise-base:ubuntu` with:

- `apt update` + `apt upgrade -y`
- Docker CLI pinned to `27.5.1`
- `@openai/codex@latest` installed globally via `npm`
- `claude` CLI installed via official installer and exposed globally via `/usr/local/bin/claude`
- shell aliases managed in `/etc/skel/.bash_aliases` and auto-copied to user home on first interactive bash session:
  - `codex='command codex --dangerously-bypass-approvals-and-sandbox'`
  - `claude='command claude --dangerously-skip-permissions'`

## Tags

- `latest`
- `nightly`

## Build locally

```bash
docker build -t codercom-ubuntu-with-docker27:local .
```

## Run

```bash
docker run --rm -it codercom-ubuntu-with-docker27:local bash
```
