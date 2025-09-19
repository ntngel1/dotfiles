#!/usr/bin/env bash
set -euo pipefail

bold() { printf "\033[1m%s\033[0m\n" "$*"; }

main() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required" >&2; exit 1
  fi

  bold "Enabling and starting services"
  if brew list redis >/dev/null 2>&1; then
    brew services enable redis || true
    brew services start redis || true
  fi
}

main "$@"

