# =============================================================================
# Development Environment Setup
# =============================================================================
# Two-phase setup for the development environment on Bluefin DX.
#
# Phase 1 — ujust setup-dev-env-part1:
#   Installs shell environment and creates directory structure.
#   Does NOT require authentication. Reboots at the end.
#
# Phase 2 — ujust setup-dev-env-part2:
#   Requires 1Password configured and SSH key added to GitHub.
#   Run after rebooting from Part 1.
#   Sub-commands available individually:
#     ujust setup-dotfiles
#     ujust setup-java
#     ujust setup-python
#     ujust setup-node
#     ujust setup-ai
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1
# ─────────────────────────────────────────────────────────────────────────────

# Phase 1 — Shell setup + directory structure (no authentication required)
[group('Dev Environment')]
setup-dev-env-part1: _setup-dirs _setup-omz _setup-p10k _setup-zsh-plugins _setup-zsh-default
    @echo ""
    @echo "✅ Phase 1 complete. The system will reboot in 10 seconds..."
    @echo "   After rebooting:"
    @echo "   1. Configure 1Password and add your SSH key to GitHub"
    @echo "   2. Run: ujust setup-dev-env-part2"
    @echo ""
    sleep 10
    systemctl reboot

# Create ~/Dev/ directory structure
[group('Dev Environment')]
[private]
_setup-dirs:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ">>> Creating ~/Dev/ directory structure..."
    # Create only directories that are NOT managed by their own installers.
    # The following are intentionally excluded:
    #   - sdkman: installer detects existing dir and aborts
    #   - pyenv:  installer uses git clone, fails on non-empty dir
    #   - poetry: installer manages its own dir
    #   - nvm:    installer uses git clone, fails on non-empty dir
    mkdir -p \
        "$HOME/Dev/repos" \
        "$HOME/Dev/tools/node/npm" \
        "$HOME/Dev/tools/java/gradle" \
        "$HOME/Dev/tools/java/m2" \
        "$HOME/Dev/tools/ai/claude" \
        "$HOME/Dev/tools/ai/gemini" \
        "$HOME/Dev/tools/ai/gemini-config"
    echo "    Done."

# Install Oh My Zsh
[group('Dev Environment')]
[private]
_setup-omz:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo ">>> Oh My Zsh already installed — skipping"
        exit 0
    fi
    echo ">>> Installing Oh My Zsh..."
    RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "    Done."

# Install Powerlevel10k theme
[group('Dev Environment')]
[private]
_setup-p10k:
    #!/usr/bin/env bash
    set -euo pipefail
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$P10K_DIR" ]]; then
        echo ">>> Powerlevel10k already installed — skipping"
        exit 0
    fi
    echo ">>> Installing Powerlevel10k..."
    GIT_CONFIG_NOSYSTEM=1 HOME=/tmp git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "    Done."

# Install ZSH plugins via Homebrew + git clone
[group('Dev Environment')]
[private]
_setup-zsh-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    echo ">>> Installing ZSH plugins via Homebrew..."
    brew install \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        zsh-history-substring-search \
        zsh-completions
    echo "    Homebrew plugins done."

    echo ">>> Installing ZSH plugins via git clone..."

    # zsh-bat
    if [[ -d "$OMZ_CUSTOM/plugins/zsh-bat" ]]; then
        echo "    zsh-bat already installed — skipping"
    else
        echo "    Installing zsh-bat..."
        GIT_CONFIG_NOSYSTEM=1 HOME=/tmp git clone --depth=1 https://github.com/fdellwing/zsh-bat.git \
            "$OMZ_CUSTOM/plugins/zsh-bat"
    fi

    # zsh-z
    if [[ -d "$OMZ_CUSTOM/plugins/zsh-z" ]]; then
        echo "    zsh-z already installed — skipping"
    else
        echo "    Installing zsh-z..."
        GIT_CONFIG_NOSYSTEM=1 HOME=/tmp git clone --depth=1 https://github.com/agkozak/zsh-z.git \
            "$OMZ_CUSTOM/plugins/zsh-z"
    fi

    echo "    Done."

# Set ZSH as the default shell
# Bluefin DX ships ZSH at /usr/bin/zsh — no installation needed, just set as default
[group('Dev Environment')]
[private]
_setup-zsh-default:
    #!/usr/bin/env bash
    set -euo pipefail
    ZSH_PATH="/usr/bin/zsh"
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
        echo ">>> ZSH already set as default shell — skipping"
        exit 0
    fi
    echo ">>> Setting ZSH as default shell..."
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
    sudo usermod -s "$ZSH_PATH" "$USER"
    echo "    Done."

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2
# ─────────────────────────────────────────────────────────────────────────────

# Phase 2 — Dotfiles + dev tools (requires 1Password configured + SSH key on GitHub)
[group('Dev Environment')]
setup-dev-env-part2: setup-java setup-python setup-node setup-ai setup-dotfiles
    @echo ""
    @echo "✅ Phase 2 complete. Your development environment is ready."
    @echo "   Open a new terminal to apply all changes."
    @echo ""

# Apply dotfiles via chezmoi
[group('Dev Environment')]
setup-dotfiles:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ">>> Applying dotfiles via chezmoi..."
    if chezmoi git status &>/dev/null 2>&1; then
        echo "    chezmoi already initialised — running apply..."
        chezmoi apply
    else
        chezmoi init --apply git@github.com:nonatorw/chezmoi-dotfiles.git
    fi
    echo "    Done."

# Install SDKMan + Java LTS + Maven + Gradle
[group('Dev Environment')]
setup-java:
    #!/usr/bin/env bash
    # SDKMan and its sdk commands use optional/unbound variables internally.
    # set -u must be disabled for the entire script to avoid spurious failures.
    set -eo pipefail
    export SDKMAN_DIR="$HOME/Dev/tools/java/sdkman"

    # Install SDKMan
    # SDKMAN_DIR must be passed inline to the installer — export alone is not enough
    if [[ ! -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        echo ">>> Installing SDKMan to $SDKMAN_DIR..."
        curl -s "https://get.sdkman.io" | SDKMAN_DIR="$SDKMAN_DIR" bash
    else
        echo ">>> SDKMan already installed — skipping"
    fi

    # Load SDKMan into current session
    source "$SDKMAN_DIR/bin/sdkman-init.sh"

    # Java LTS
    if [[ ! -d "$SDKMAN_DIR/candidates/java/current" ]]; then
        echo ">>> Installing Java LTS (Temurin)..."
        sdk install java
    else
        echo ">>> Java already installed — skipping"
    fi

    # Maven
    if [[ ! -d "$SDKMAN_DIR/candidates/maven/current" ]]; then
        echo ">>> Installing Maven..."
        sdk install maven
    else
        echo ">>> Maven already installed — skipping"
    fi

    # Gradle
    if [[ ! -d "$SDKMAN_DIR/candidates/gradle/current" ]]; then
        echo ">>> Installing Gradle..."
        sdk install gradle
    else
        echo ">>> Gradle already installed — skipping"
    fi

    echo "    Java environment ready."

# Install PyEnv + Python (latest stable) + Poetry
[group('Dev Environment')]
setup-python:
    #!/usr/bin/env bash
    set -eo pipefail
    export PYENV_ROOT="$HOME/Dev/tools/python/pyenv"
    export POETRY_HOME="$HOME/Dev/tools/python/poetry"
    export PATH="$PYENV_ROOT/bin:$PATH"

    # Install Python build dependencies via Homebrew
    # On Bluefin (immutable system), these cannot be installed via dnf at runtime.
    # PyEnv compiles Python from source and requires these libraries.
    echo ">>> Installing Python build dependencies via Homebrew..."
    brew install openssl readline sqlite3 xz zlib bzip2 libffi ncurses

    # Install PyEnv
    # GIT_CONFIG_NOSYSTEM and HOME override prevent conflicts with user .gitconfig
    # (e.g. 1Password SSH signing config causes git clone to fail)
    if [[ ! -d "$PYENV_ROOT/.git" ]]; then
        echo ">>> Installing PyEnv..."
        GIT_CONFIG_NOSYSTEM=1 HOME=/tmp git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
        cd "$PYENV_ROOT" && src/configure && make -C src 2>/dev/null; cd - >/dev/null
    else
        echo ">>> PyEnv already installed — skipping"
    fi

    # Set build flags so PyEnv finds the Homebrew libraries
    BREW_PREFIX="$(brew --prefix)"
    export LDFLAGS="-L$BREW_PREFIX/lib"
    export CPPFLAGS="-I$BREW_PREFIX/include"
    export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig"

    eval "$(pyenv init - bash)"

    # Python latest stable 3.x
    LATEST_PY="$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')"
    if pyenv versions --bare | grep -qx "$LATEST_PY"; then
        echo ">>> Python $LATEST_PY already installed — setting as global"
    else
        echo ">>> Installing Python $LATEST_PY..."
        pyenv install "$LATEST_PY"
    fi
    pyenv global "$LATEST_PY"
    echo "    Active Python: $(python --version)"

    # Poetry
    if [[ ! -f "$POETRY_HOME/bin/poetry" ]]; then
        echo ">>> Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
        "$POETRY_HOME/bin/poetry" config virtualenvs.in-project true
    else
        echo ">>> Poetry already installed — skipping"
    fi

    echo "    Python environment ready."

# Install NVM + Node.js LTS
[group('Dev Environment')]
setup-node:
    #!/usr/bin/env bash
    # NVM uses optional/unbound variables internally.
    # set -u must be disabled for the entire script.
    set -eo pipefail
    export NVM_DIR="$HOME/Dev/tools/node/nvm"
    export NPM_CONFIG_CACHE="$HOME/Dev/tools/node/npm"

    # Install NVM
    if [[ ! -f "$NVM_DIR/nvm.sh" ]]; then
        echo ">>> Installing NVM..."
        LATEST_NVM="$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" \
            | grep '"tag_name"' | sed -E 's/.*"(v[^"]+)".*/\1/')"
        GIT_CONFIG_NOSYSTEM=1 HOME=/tmp git clone --depth=1 --branch "$LATEST_NVM" https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    else
        echo ">>> NVM already installed — skipping"
    fi

    source "$NVM_DIR/nvm.sh"

    # Node.js LTS
    CURRENT_NODE="$(nvm current 2>/dev/null || echo 'none')"
    if [[ "$CURRENT_NODE" != "none" && "$CURRENT_NODE" != "N/A" ]]; then
        echo ">>> Node.js already installed: $CURRENT_NODE — skipping"
    else
        echo ">>> Installing Node.js LTS..."
        nvm install --lts
        nvm alias default 'lts/*'
        echo "    Node.js: $(node --version)"
    fi

    echo "    Node.js environment ready."

# Install Claude Code + Gemini CLI
[group('Dev Environment')]
setup-ai:
    #!/usr/bin/env bash
    set -euo pipefail
    export CLAUDE_HOME="$HOME/Dev/tools/ai/claude"
    export GEMINI_HOME="$HOME/Dev/tools/ai/gemini"
    export NVM_DIR="$HOME/Dev/tools/node/nvm"

    # Load NVM to make node available
    # NVM uses optional variables — disable set -u for this block
    set +u
    source "$NVM_DIR/nvm.sh" 2>/dev/null || true
    set -u

    # Requires Node.js
    if ! command -v node &>/dev/null; then
        echo "ERROR: Node.js not found. Run 'ujust setup-node' first."
        exit 1
    fi

    # Claude Code
    if [[ -f "$CLAUDE_HOME/bin/claude" ]]; then
        echo ">>> Claude Code already installed — skipping"
    else
        echo ">>> Installing Claude Code..."
        npm install --prefix "$CLAUDE_HOME" @anthropic-ai/claude-code
    fi

    # Gemini CLI
    if [[ -f "$GEMINI_HOME/bin/gemini" ]]; then
        echo ">>> Gemini CLI already installed — skipping"
    else
        echo ">>> Installing Gemini CLI..."
        npm install --prefix "$GEMINI_HOME" @google/gemini-cli
        mkdir -p "$GEMINI_HOME/bin"
        ln -sf "../node_modules/.bin/gemini" "$GEMINI_HOME/bin/gemini"
    fi

    # Gemini config symlink
    if [[ ! -L "$HOME/.gemini" ]]; then
        echo ">>> Creating ~/.gemini symlink..."
        ln -sf "$HOME/Dev/tools/ai/gemini-config" "$HOME/.gemini"
    fi

    echo "    AI tools ready."
