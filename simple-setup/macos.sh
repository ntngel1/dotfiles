#!/usr/bin/env bash
set -euo pipefail

# Applies macOS defaults to mirror settings from your previous nix-darwin config.
# Run anytime; can be re-applied safely. Some changes require logout or reboot.

bold() { printf "\033[1m%s\033[0m\n" "$*"; }

require_sudo() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    if ! sudo -v; then
      echo "sudo auth required" >&2; exit 1
    fi
  fi
}

os_defaults() {
  bold "Setting Dock preferences"
  defaults write com.apple.dock show-recents -bool false
  # Bottom-right hot corner = Desktop (1)
  defaults write com.apple.dock wvous-br-corner -int 1

  bold "Setting Finder preferences"
  defaults write com.apple.finder AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true

  bold "Setting Control Center and global preferences"
  defaults write com.apple.controlcenter BatteryShowPercentage -bool true
  defaults write -g AppleInterfaceStyle -string "Dark" || true
  defaults write -g KeyRepeat -int 2
  defaults write -g InitialKeyRepeat -int 15
  defaults write -g com.apple.keyboard.fnState -bool true

  bold "Disable window margins for tiled windows"
  defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false || true

  bold "Setting Safari"
  defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
  defaults write com.apple.Safari AutoOpenSafeDownloads -bool false


  bold "Adjust screenshot hotkeys (disable 28,30; enable 29,31 to clipboard)"
  local plist="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys dict" "$plist" 2>/dev/null || true
  # Disable default screenshot shortcuts (28 and 30)
  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:28 dict" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:28:enabled false" "$plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:28:enabled bool false" "$plist" 2>/dev/null || true

  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:30 dict" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:30:enabled false" "$plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:30:enabled bool false" "$plist" 2>/dev/null || true

  # Enable custom clipboard screenshots for 29 and 31
  for key in 29 31; do
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key} dict" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled true" "$plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:enabled bool true" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value dict" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:value:type standard" "$plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:type string standard" "$plist" 2>/dev/null || true
    # parameters = [51, 20, 1179648]
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:parameters array" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:${key}:value:parameters" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:parameters array" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:0 integer 51" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:1 integer 20" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:2 integer 1179648" "$plist" 2>/dev/null || true
  done

  bold "Applying pmset for display sleep (5 minutes)"
  require_sudo
  sudo pmset -a displaysleep 5

  bold "Restarting affected services"
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
}

configure_dock_layout() {
  # Requires dockutil (installed via Brewfile)
  if ! command -v dockutil >/dev/null 2>&1; then
    echo "dockutil not found; skipping Dock layout" >&2
    return 0
  fi

  bold "Configuring Dock layout"
  # Remove existing persistent apps (keep others like Downloads)
  dockutil --remove all --no-restart || true

  add_app() {
    local app="$1"
    if [[ -d "$app" ]]; then
      dockutil --add "$app" --no-restart || true
    fi
  }

  add_app "/System/Applications/Mail.app"
  add_app "/Applications/Telegram.app"
  add_app "/Applications/Safari.app"
  add_app "/System/Applications/Notes.app"
  add_app "/Applications/Spotify.app"
  add_app "/Applications/Shadowrocket.app" # if installed
  add_app "/Applications/Hoppscotch.app"
  add_app "/Applications/IntelliJ IDEA.app"
  add_app "/System/Applications/Utilities/Terminal.app"

  killall Dock 2>/dev/null || true
}

enable_touch_id_for_sudo() {
  bold "Enabling Touch ID for sudo (watchID)"
  require_sudo
  local pam_file="/etc/pam.d/sudo"
  if [[ -f "$pam_file" ]] && ! grep -q "pam_watchid.so" "$pam_file"; then
    sudo sed -i.bak '1s;^;auth       sufficient     pam_watchid.so\n;' "$pam_file"
    echo "Updated $pam_file (backup at $pam_file.bak)"
  else
    echo "Touch ID for sudo already configured or file missing; skipping"
  fi
}

main() {
  os_defaults
  configure_dock_layout
  enable_touch_id_for_sudo
  bold "macOS configuration complete"
}

main "$@"

