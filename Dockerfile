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
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc; \
      source ~/.bashrc; \
    fi; \
    BASH_ALIASES_FILE="$HOME/.bash_aliases"; \
    touch "$BASH_ALIASES_FILE"; \
    sed -i '/# BEGIN coder-managed-cli-aliases/,/# END coder-managed-cli-aliases/d' "$BASH_ALIASES_FILE"; \
    printf '%s\n' \
      '# BEGIN coder-managed-cli-aliases' \
      "alias codex='command codex --dangerously-bypass-approvals-and-sandbox'" \
      "alias claude='command claude --dangerously-skip-permissions'" \
      '# END coder-managed-cli-aliases' \
      >> "$BASH_ALIASES_FILE"
