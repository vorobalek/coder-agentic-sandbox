FROM codercom/enterprise-base:ubuntu

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    SUDO=""; \
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi; \
    ${SUDO} apt update; \
    DEBIAN_FRONTEND=noninteractive ${SUDO} apt upgrade -y; \
    DOCKER_CLI_VERSION="27.5.1"; \
    INSTALLED_DOCKER_CLI_VERSION="$(docker version --format '{{.Client.Version}}' 2>/dev/null || true)"; \
    if [ "$INSTALLED_DOCKER_CLI_VERSION" != "$DOCKER_CLI_VERSION" ]; then \
      DOCKER_CLI_URL="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz"; \
      curl -fsSL "$DOCKER_CLI_URL" -o /tmp/docker.tgz \
        && ${SUDO} tar -xz --strip-components=1 -C /usr/local/bin/ -f /tmp/docker.tgz docker/docker \
        && rm -f /tmp/docker.tgz; \
    fi; \
    if ! command -v codex >/dev/null 2>&1; then \
      if ! command -v npm >/dev/null 2>&1; then \
        DEBIAN_FRONTEND=noninteractive ${SUDO} apt install -y npm; \
      fi; \
      ${SUDO} npm install -g @openai/codex@latest; \
    fi; \
    if ! command -v claude >/dev/null 2>&1; then \
      curl -fsSL https://claude.ai/install.sh | bash; \
    fi; \
    CLAUDE_BIN=""; \
    for candidate in /usr/local/bin/claude "$HOME/.local/bin/claude" /root/.local/bin/claude /home/coder/.local/bin/claude; do \
      if [ -x "$candidate" ]; then \
        CLAUDE_BIN="$candidate"; \
        break; \
      fi; \
    done; \
    if [ -z "$CLAUDE_BIN" ]; then \
      echo "claude binary not found after installation" >&2; \
      exit 1; \
    fi; \
    if [ "$CLAUDE_BIN" != "/usr/local/bin/claude" ]; then \
      ${SUDO} ln -sf "$CLAUDE_BIN" /usr/local/bin/claude; \
    fi; \
    BASH_ALIASES_FILE="/etc/skel/.bash_aliases"; \
    ${SUDO} mkdir -p /etc/skel; \
    ${SUDO} touch "$BASH_ALIASES_FILE"; \
    ${SUDO} sed -i '/# BEGIN coder-managed-cli-aliases/,/# END coder-managed-cli-aliases/d' "$BASH_ALIASES_FILE"; \
    printf '%s\n' \
      '# BEGIN coder-managed-cli-aliases' \
      "alias codex='command codex --dangerously-bypass-approvals-and-sandbox'" \
      "alias claude='command claude --dangerously-skip-permissions'" \
      '# END coder-managed-cli-aliases' \
      | ${SUDO} tee -a "$BASH_ALIASES_FILE" >/dev/null

RUN set -eux; \
    SUDO=""; \
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi; \
    SYSTEM_BASHRC="/etc/bash.bashrc"; \
    if [ ! -f "$SYSTEM_BASHRC" ]; then \
      ${SUDO} touch "$SYSTEM_BASHRC"; \
    fi; \
    ${SUDO} sed -i '/# BEGIN coder-managed-cli-init/,/# END coder-managed-cli-init/d' "$SYSTEM_BASHRC"; \
    cat <<'EOF' | ${SUDO} tee -a "$SYSTEM_BASHRC" >/dev/null
# BEGIN coder-managed-cli-init
export PATH="$HOME/.local/bin:$PATH"
alias codex='command codex --dangerously-bypass-approvals-and-sandbox'
alias claude='command claude --dangerously-skip-permissions'
if [ -n "${HOME:-}" ] && [ -d "$HOME" ] && [ -w "$HOME" ] && [ ! -f "$HOME/.bash_aliases" ] && [ -f "/etc/skel/.bash_aliases" ]; then
  cp /etc/skel/.bash_aliases "$HOME/.bash_aliases"
fi
# END coder-managed-cli-init
EOF
