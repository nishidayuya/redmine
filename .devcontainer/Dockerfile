FROM mcr.microsoft.com/devcontainers/base:debian-13

# Several RUN instructions below pipe a downloaded installer script or GPG key
# into another command. The default "/bin/sh -c" only reports the exit status of
# the last command of a pipeline, so a failed download would go unnoticed.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install git, gh, glab, Chromium, and other dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    git \
    gh \
    glab \
    openssh-client \
    iptables \
    curl \
    ca-certificates \
    gpg \
    gnupg \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    dbus \
    kmod \
    chromium \
    chromium-driver \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install mise
# The repository serves both amd64 and arm64, so the architecture is taken from
# dpkg instead of being named: hard-coding amd64 leaves "apt-get install mise"
# without a candidate on an arm64 host, such as an Apple Silicon Mac.
RUN arch="$(dpkg --print-architecture)" \
    && install -dm 755 /etc/apt/keyrings \
    && curl -fsSL --retry 3 --retry-all-errors https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=${arch}] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mise \
    && rm -rf /var/lib/apt/lists/*

USER vscode
ENV MISE_DATA_DIR=/home/vscode/.local/share/mise
ENV MISE_CONFIG_DIR=/home/vscode/.config/mise
ENV PATH="/home/vscode/.local/bin:/home/vscode/.devcontainers/bin:/home/vscode/.local/share/mise/shims:${PATH}"

# DevPod reports anonymous usage statistics unless told not to. The firewall
# blocks that endpoint anyway, so turn it off rather than have every invocation
# wait on a rejected connection.
ENV DEVPOD_DISABLE_TELEMETRY=true

# Install tools
# Dev Container CLI is installed with the standalone script, which bundles its
# own Node.js runtime (https://github.com/devcontainers/cli#install-script)
RUN curl -fsSL --retry 3 --retry-all-errors https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh
# DevPod CLI runs the same devcontainer.json on a pluggable backend. It ships as
# a single static binary (https://devpod.sh/docs/getting-started/install), and
# the built-in "docker" provider is registered here so that it targets the local
# Docker daemon provided by the docker-in-docker feature. That provider is
# embedded in the binary, so adding it needs no network access.
#
# Git credential and ssh signature forwarding are turned off because both work
# by rewriting ~/.gitconfig inside the workspace. Here that file is a symlink
# into /dev_container_home (see post_start_command.d/10-dev-container-home), so
# DevPod would edit the shared configuration on the host and leave behind a
# credential helper and a gpg.ssh.program pointing at paths that only exist
# inside the workspace, breaking git outside of it.
#
# The default IDE is set to "none" because DevPod otherwise falls back to
# opening VS Code, and there is none to open in here. "devpod up" then just
# starts the workspace, and "devpod ssh" is how you enter it.
#
# The binary is downloaded straight to its final location: DevPod itself uses
# /tmp/devpod as a working directory, so staging the download there would make
# every later "mkdir /tmp/devpod" fail with "not a directory".
RUN arch="$(dpkg --print-architecture)" \
    && install -d -m 0755 /home/vscode/.local/bin \
    && curl -fsSL --retry 3 --retry-all-errors -o /home/vscode/.local/bin/devpod \
      "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-${arch}" \
    && chmod 0755 /home/vscode/.local/bin/devpod \
    && devpod provider add docker \
    && devpod context set-options \
      -o SSH_INJECT_GIT_CREDENTIALS=false \
      -o GIT_SSH_SIGNATURE_FORWARDING=false \
    && devpod ide use none
# Install Claude Code via the native installer (https://code.claude.com/docs/ja/quickstart)
RUN curl -fsSL --retry 3 --retry-all-errors https://claude.ai/install.sh | bash
# Antigravity CLI is distributed as a native binary (installed to ~/.local/bin/agy), not via npm
RUN curl -fsSL --retry 3 --retry-all-errors https://antigravity.google/cli/install.sh | bash
RUN mise use -g ruby@latest
# Node.js is not required anymore: the Dev Container CLI standalone installer
# bundles its own runtime. Uncomment if your project needs Node.js and npm.
# RUN mise use -g node@24
# Rust is not installed by default. Uncomment if your project needs rustc and
# cargo. mise installs and drives rustup under the hood.
# RUN mise use -g rust@latest
# Git is already provided by apt above. Uncomment to manage a newer Git with
# mise instead, using the asdf-git plugin
# (https://github.com/nishidayuya/asdf-git). It builds Git from source, so the
# first RUN below installs Git's extra build dependencies. Git 2.55 and later
# also build Rust code (libgitcore) unless NO_RUST is set, so the rust line
# above has to be uncommented too.
# RUN sudo apt-get update \
#     && sudo env -- DEBIAN_FRONTEND=noninteractive \
#     apt-get -y install --no-install-recommends \
#     gettext \
#     libcurl4-openssl-dev \
#     libexpat1-dev
# RUN mise plugin add git https://github.com/nishidayuya/asdf-git \
#     && mise use -g git@latest

# Setup shell for mise
# The single quotes are deliberate: mise has to be activated when the shell
# starts, not when the image is built.
# hadolint ignore=SC2016
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc \
    && echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Load ~/.bashrc.local.d and ~/.zshrc.local.d
# A drop-in directory keeps per-user or per-project shell settings out of the
# rc file itself, so that they can be added by symlinking them in from
# /dev_container_home (see post_start_command.d/10-dev-container-home) without
# editing anything the image ships.
#
# The blocks are appended last, so that they run after the mise activation above
# and can therefore override it. The glob expands in collation order, which is
# how the files are sourced alphabetically, and it also expands to nothing
# useful when the directory is empty: bash leaves the pattern as it is and the
# -f test rejects it, while zsh's (N) qualifier drops it. A missing directory is
# not an error either.
#
# The whole thing is one heredoc so that the two blocks read the way they end up
# in the rc files. It needs BuildKit, which every builder this image is built
# with uses: the classic "DOCKER_BUILDKIT=0" builder drops heredoc bodies.
RUN <<'DOCKERFILE_RUN'
cat >> ~/.bashrc <<'BASHRC'

# Source every file in ~/.bashrc.local.d, in alphabetical order.
if [ -d ~/.bashrc.local.d ]; then
  for __rc in ~/.bashrc.local.d/*; do
    [ -f "$__rc" ] && . "$__rc"
  done
  unset __rc
fi
BASHRC

cat >> ~/.zshrc <<'ZSHRC'

# Source every file in ~/.zshrc.local.d, in alphabetical order.
if [ -d ~/.zshrc.local.d ]; then
  for __rc in ~/.zshrc.local.d/*(N); do
    [ -f "$__rc" ] && . "$__rc"
  done
  unset __rc
fi
ZSHRC
DOCKERFILE_RUN

# Everything above comes from dot-devcontainer v5.0.0
# (https://github.com/nishidayuya/dot-devcontainer) and is kept as it is, so that
# it can be updated by re-running its installer. Everything below is specific to
# the development of Redmine itself.

# The Ruby version comes from RUBY_VERSION in .devcontainer/.env, which
# docker-compose.yml passes as a build argument. See .devcontainer/.env.example.
ARG RUBY_VERSION
ARG NODE_VERSION=24

# - libpq-dev, postgresql-client: the "pg" gem and pg_isready / psql against
#   the "postgres" service. default-libmysqlclient-dev and default-mysql-client
#   are for switching config/database.yml over to the "mysql" service.
# - subversion: Git is installed above already; together they are the SCMs
#   that Redmine offers in this Dev Container.
# - bzr (Breezy), cvs, mercurial: the other SCMs Redmine supports, so that
#   their tests run instead of skipping themselves.
# - locales: the en_US.ISO-8859-1 locale generated below.
# - imagemagick, ghostscript, gsfonts: attachment thumbnails and the Gantt PNG
#   export.
# - pandoc: Redmine::Markdownizer, which previews .docx and friends as
#   Markdown. Without it those attachment tests skip themselves.
# - fonts-liberation: Chromium renders the system tests with it.
# hadolint ignore=DL3008
RUN sudo apt-get update \
    && sudo env -- DEBIAN_FRONTEND=noninteractive \
    apt-get -y install --no-install-recommends \
    bzr \
    cvs \
    default-libmysqlclient-dev \
    default-mysql-client \
    fonts-liberation \
    ghostscript \
    gsfonts \
    imagemagick \
    locales \
    mercurial \
    iproute2 \
    libpq-dev \
    pandoc \
    pkg-config \
    postgresql-client \
    subversion \
    && sudo rm -rf /var/lib/apt/lists/*

# The Bazaar tests with non-ASCII paths run in this locale, the same way as
# .github/workflows/tests.yml runs test/unit/repository_bazaar_test.rb with
# LANG=en_US.ISO8859-1.
RUN echo "en_US ISO-8859-1" | sudo tee -a /etc/locale.gen > /dev/null \
    && sudo locale-gen

# /usr/bin/brz of Breezy 3.3 is a launcher written in Rust, which panics when
# an argument is not valid UTF-8, such as the Latin-1 paths of the Bazaar tests
# above (https://www.redmine.org/issues/42024). Redmine runs "bzr", so put a
# "bzr" that starts Breezy through Python, which accepts any bytes, ahead of it
# on PATH.
RUN printf '%s\n' '#!/bin/sh' 'exec /usr/bin/python3 -m breezy "$@"' \
    | sudo tee /usr/local/bin/bzr > /dev/null \
    && sudo chmod 0755 /usr/local/bin/bzr

# ImageMagick 7 dropped the "convert" entry point, but Redmine::Thumbnail still
# calls it. Provide it when only "magick" is installed.
RUN command -v convert > /dev/null \
    || sudo ln -s "$(command -v magick)" /usr/local/bin/convert

# Debian's ImageMagick refuses to read PDFs, which makes the attachment
# thumbnail tests fail. Upstream CI does the same thing, see
# .github/actions/setup-redmine/action.yml.
RUN for dir in /etc/ImageMagick-6 /etc/ImageMagick-7; do \
      test -d "${dir}" || continue; \
      printf '%s\n' \
        '<policymap>' \
        '<policy domain="coder" rights="read | write" pattern="PDF" />' \
        '</policymap>' | sudo tee "${dir}/policy.xml" > /dev/null; \
    done

# "ruby@latest" above may be newer than what Redmine's Gemfile accepts, so the
# version from .devcontainer/.env becomes the global default instead.
RUN test -n "${RUBY_VERSION}" \
    && mise use -g "ruby@${RUBY_VERSION}" \
    && ruby --version

# Node.js runs Playwright MCP and stylelint (see .github/workflows/linters.yml,
# which drives it through yarn). Playwright MCP drives the Chromium installed
# above instead of downloading a browser of its own, see /.mcp.json.
RUN mise use -g "node@${NODE_VERSION}" \
    && npm install --global yarn @playwright/mcp \
    && mise reshim \
    && playwright-mcp --version

# Gems are installed into the bind-mounted workspace (see BUNDLE_PATH in
# docker-compose.yml), so make bin/ of the workspace reachable too.
ENV PATH="/workspaces/redmine/bin:${PATH}"
