#!/usr/bin/env bash
set -euo pipefail

# Symlink dotfiles from this repo and ensure zsh aliases/env are present.

bold() { printf "\033[1m%s\033[0m\n" "$*"; }

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  echo "Linked $dst -> $src"
}

add_zsh_block() {
  local zshrc="$HOME/.zshrc"
  local marker_begin="# >>> simple-setup managed >>>"
  local marker_end="# <<< simple-setup managed <<<"
  local block="\n$marker_begin\n# Environment\nexport EDITOR=vim\n\n# Aliases\nalias ls='ls -la'\nalias mongostage='mongosh mongodb://10.40.0.35:27017/kinokassa'\n$marker_end\n"

  if [[ -f "$zshrc" ]] && grep -q "$marker_begin" "$zshrc"; then
    # Replace existing managed block
    awk -v RS= -v ORS="" -v b="$marker_begin" -v e="$marker_end" -v blk="$block" '
      { if ($0 ~ b && $0 ~ e) { gsub(b"[\n\r\0-\x7F]*"e, blk) } } 1' "$zshrc" >"$zshrc.tmp"
    mv "$zshrc.tmp" "$zshrc"
    echo "Updated managed zsh block in $zshrc"
  else
    printf "%s" "$block" >>"$zshrc"
    echo "Appended managed zsh block to $zshrc"
  fi
}

main() {
  bold "Linking dotfiles"
  if [[ -f "$REPO_DIR/.ideavimrc" ]]; then
    link_file "$REPO_DIR/.ideavimrc" "$HOME/.ideavimrc"
  fi
  if [[ -f "$REPO_DIR/.vimrc" ]]; then
    link_file "$REPO_DIR/.vimrc" "$HOME/.vimrc"
  fi

  bold "Updating zsh aliases and EDITOR"
  add_zsh_block
}

main "$@"

