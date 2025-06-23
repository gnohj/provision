#!/usr/bin/env bash
# Bootstraps: MacOS/Linux
# This script sets up a new machine by installing essentials and running Ansible/Chezmoi

set -euo pipefail

ANSIBLE_REPO="ansible-personal-workstation"
DOTFILES_REPO="dotfiles"
ZZH_ZEY_ZECRET_NAME="GITHUB_ZZH_PRIVATE_ZEY"

if [ -z "${2-}" ]; then
  echo "Error: Both Bitwarden email and GitHub username are required." >&2
  echo "Usage: ./bootstrap.sh your_email@example.com your_github_username" >&2
  exit 1
fi
BW_EMAIL="$1"
GIT_USERNAME="$2"

# --- Configuration (with defaults for optional arguments) ---
DOTFILES_REPO="${3:-dotfiles}"
ANSIBLE_BASE_PATH="${4:-$HOME}"
ANSIBLE_REPO="${5:-ansible-personal-workstation}"
ANSIBLE_REPO_PATH="$ANSIBLE_BASE_PATH/$ANSIBLE_REPO"

print_info() {
  printf "\n\e[1;34m%s\e[0m\n" "$1"
}

OS="$(uname -s)"
case "$OS" in
Linux)
  SUDO="sudo"
  ;;
Darwin)
  SUDO=""
  ;;
*)
  echo "Unsupported operating system: $OS" >&2
  exit 1
  ;;
esac

# PHASE 1: INSTALL BASE TOOLS AND SET UP ZZH
print_info "› Phase 1: Installing base tools..."
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &>/dev/null; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew update
  brew install git chezmoi ansible rbw
elif [ "$OS" = "Linux" ]; then
  $SUDO apt-get update
  $SUDO apt-get install -y build-essential git curl python3-pip

  RBW_VERSION="1.8.0"
  RBW_DEB="rbw_${RBW_VERSION}_amd64.deb"
  curl -fsSLO "https://github.com/doy/rbw/releases/download/v${RBW_VERSION}/${RBW_DEB}"
  $SUDO apt-get install -y "./${RBW_DEB}"
  rm "./${RBW_DEB}"

  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
  pip3 install ansible
fi

if [ -f "$HOME/.ssh/id_ed25519" ]; then
  print_info "ZZH zey already exists. Skipping setup."
else
  mkdir -p "$HOME/.config/rbw"
  printf "[main]\nemail = %s\n" "$BW_EMAIL" >"$HOME/.config/rbw/config.ini"

  print_info "Please enter your Bitwarden master password to unlock the vault."
  if ! eval "$(rbw unlock)"; then
    echo "Failed to unlock Bitwarden (incorrect password?). Exiting." >&2
    exit 1
  fi
  print_info "Vault unlocked successfully."

  print_info "Syncing vault..."
  if ! rbw sync; then
    echo "Failed to sync Bitwarden vault. Exiting." >&2
    exit 1
  fi

  print_info "Vault synced successfully. Fetching zzh key..."
  PRIVATE_ZEY=$(rbw get "$ZZH_ZEY_ZECRET_NAME")

  print_info "Configuring ZZH..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  printf "%s" "$PRIVATE_ZEY" >"$HOME/.ssh/id_ed25519"
  chmod 600 "$HOME/.ssh/id_ed25519"

  ssh-keyscan github.com >>"$HOME/.ssh/known_hosts" 2>/dev/null
  print_info "ZZH key configured successfully."
fi

# PHASE 2: RUN ANSIBLE TO PROVISION SYSTEM
# print_info "› Phase 2: Cloning and running Ansible playbook..."
# mkdir -p "$ANSIBLE_BASE_PATH"
# if [ -d "$ANSIBLE_REPO_PATH" ]; then
#   print_info "Ansible repo already exists. Pulling latest changes."
#   cd "$ANSIBLE_REPO_PATH" && git pull
# else
#   git clone "git@github.com:$GIT_USERNAME/$ANSIBLE_REPO.git" "$ANSIBLE_REPO_PATH"
# fi
# cd "$ANSIBLE_REPO_PATH"
# ansible-playbook main.yml --ask-become-pass

# PHASE 3: APPLY DOTFILES WITH CHEZMOI
print_info "› Phase 3: Initializing Chezmoi to apply dotfiles..."
chezmoi init "$GIT_USERNAME/$DOTFILES_REPO"
# Update chezmoi.toml config file so that  [data] installPackages = true / newMachine = true
# Then run chezmoi apply -v
# chezmoi apply -v

print_info "✅ Bootstrap complete! Your new machine is ready."
