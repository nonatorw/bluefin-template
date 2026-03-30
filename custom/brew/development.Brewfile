# Brewfile for development tools
# Run with: brew bundle --file=~/.local/share/ublue-os/homebrew/development.Brewfile
# Or via: ujust brew-bundle

# -----------------------------------------------------------------------------
# Shell
# -----------------------------------------------------------------------------
brew "zsh-autosuggestions"       # Fish-like autosuggestions for ZSH
brew "zsh-syntax-highlighting"   # Fish-like syntax highlighting for ZSH

# Oh My Zsh (installed via script, not brew — kept here as documentation)
# Install manually: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Powerlevel10k (installed via Oh My Zsh custom themes)
# Install manually: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# -----------------------------------------------------------------------------
# Java ecosystem (via SDKMAN — installed via script, not brew)
# -----------------------------------------------------------------------------
# SDKMAN manages Java, Maven and Gradle versions independently.
# Install manually: curl -s "https://get.sdkman.io" | bash
# Then: sdk install java / sdk install maven / sdk install gradle

# -----------------------------------------------------------------------------
# Python ecosystem
# -----------------------------------------------------------------------------
brew "pyenv"                      # Python version manager
brew "pyenv-virtualenv"           # Virtualenv plugin for pyenv

# Poetry (recommended install via pipx after pyenv sets a Python version)
brew "pipx"                       # Install Python CLI tools in isolated envs
# After first boot: pipx install poetry

# -----------------------------------------------------------------------------
# Node.js ecosystem
# -----------------------------------------------------------------------------
brew "nvm"                        # Node version manager

# -----------------------------------------------------------------------------
# AI coding assistants
# -----------------------------------------------------------------------------
cask "claude-code"                # Anthropic's Claude CLI coding agent
brew "gemini-cli"                 # Google Gemini CLI coding agent

# -----------------------------------------------------------------------------
# Modern CLI tools
# -----------------------------------------------------------------------------
brew "bat"                        # cat with syntax highlighting
brew "fd"                         # Simple, fast alternative to find
brew "fzf"                        # Fuzzy finder
brew "jq"                         # JSON processor
brew "rg"                         # ripgrep - faster grep
brew "tldr"                       # Simplified man pages
brew "zoxide"                     # Smarter cd command

# -----------------------------------------------------------------------------
# Development utilities
# -----------------------------------------------------------------------------
brew "gh"                         # GitHub CLI
brew "git-delta"                  # Better git diff
brew "htop"                       # Interactive process viewer
brew "tmux"                       # Terminal multiplexer

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
brew "chezmoi"                    # Dotfiles manager (also available system-wide via rpm)
