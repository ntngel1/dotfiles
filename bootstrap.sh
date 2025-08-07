#!/bin/bash
sudo /nix/var/nix/profiles/default/bin/nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.config/nix#macbook
