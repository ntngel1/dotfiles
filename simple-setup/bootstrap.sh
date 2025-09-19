#!/usr/bin/env bash
set -euo pipefail

bold() { printf "\033[1m%s\033[0m\n" "$*"; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ensure_xcode_clt() {
  if ! xcode-select -p >/dev/null 2>&1; then
    bold "Installing Xcode Command Line Tools (GUI prompt)"
    xcode-select --install || true
    echo "Please complete Xcode CLT installation, then re-run this script if needed."
  fi
}

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    bold "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  eval "$(brew shellenv)"
}

brew_bundle() {
  bold "Installing packages via Brewfile"
  brew update
  brew bundle --no-lock --file "$SCRIPT_DIR/Brewfile"
}

apply_macos() {
  bold "Applying macOS defaults and Dock layout"
  bash "$SCRIPT_DIR/macos.sh"
}

dotfiles() {
  bold "Linking dotfiles and zsh aliases"
  bash "$SCRIPT_DIR/dotfiles.sh"
}

services() {
  bold "Enabling services (e.g., Redis)"
  bash "$SCRIPT_DIR/services.sh"
}

post_notes() {
  cat <<'EOF'

Next steps / notes:
- If MAS apps didn’t install, ensure you are signed in to the App Store app, then run:
    brew bundle --file simple-setup/Brewfile --no-lock
- Some macOS defaults require logout or reboot to fully apply.
- Verify Dock layout and adjust in simple-setup/macos.sh if desired.
- Touch ID for sudo was enabled by editing /etc/pam.d/sudo (backup saved).

EOF
}

main() {
  ensure_xcode_clt
  ensure_homebrew
  brew_bundle
  apply_macos
  dotfiles
  services
  post_notes
}

main "$@"

