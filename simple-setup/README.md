Simple macOS Setup (No Nix)

This folder provides a simple, script-based replacement for nix-darwin + home-manager on this Mac. It uses Homebrew (with a Brewfile), a macOS defaults script, minimal dotfiles wiring, and a small services script.

What it covers
- Homebrew packages, casks, and Mac App Store apps via `Brewfile`
- macOS defaults and Dock layout to match your Nix config
- Dotfiles: `.ideavimrc`, `.vimrc`, and zsh aliases/EDITOR
- Services: enables Redis via `brew services`

Quick start
1) Review and edit `simple-setup/Brewfile` to your taste.
2) (Optional) Sign in to App Store app first for MAS installs.
3) Run the bootstrap:
   bash simple-setup/bootstrap.sh

Scripts
- `bootstrap.sh` — orchestrates install steps (Brewfile, macOS defaults, dotfiles, services).
- `macos.sh` — applies system preferences (Dock, Finder, keyboard, Safari dev extras, etc.).
- `dotfiles.sh` — symlinks `.ideavimrc` and `.vimrc` from this repo and adds zsh aliases/env.
- `services.sh` — enables/starts Homebrew services (currently Redis).

Notes
- JetBrains Mono font is installed via `font-jetbrains-mono` (tap `homebrew/cask-fonts`).
- IntelliJ IDEA Ultimate cask is `intellij-idea`.
- Telegram cask is `telegram`.
- Hoppscotch has a cask `hoppscotch`.
- Devenv is available via `cachix/tap/devenv`.
- Touch ID for sudo is set by editing `/etc/pam.d/sudo` (script handles it safely).
- The Dock layout uses `dockutil` and only adds apps that are installed/present.

Uninstalling Nix (manual)
- Once you’re happy, you can remove nix-darwin and Nix. Follow the official uninstall docs or a trusted guide; do not blindly delete `/nix`.
