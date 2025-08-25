{
  description = "Reusable nix-darwin + home-manager system flake for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, mac-app-util, ... }:
  let
    system = "aarch64-darwin";

    configuration = { pkgs, config, ... }: {
      home-manager.backupFileExtension = "backup";

      environment.systemPackages = with pkgs; [
        vim
        jetbrains-mono
        telegram-desktop
        jetbrains.idea-ultimate
        mkalias
        sbt
        nodejs
        redis
        mongosh
        spotify
        hoppscotch
      ];

      homebrew = {
        enable = true;
        casks = [ "logi-options+" ];
        masApps = {
          Keynote = 409183694;
          Numbers = 409203825;
        };
        onActivation = {
          cleanup = "uninstall";
          autoUpdate = true;
          upgrade = true;
        };
      };

      nix = {
        enable = false;
        settings.experimental-features = "nix-command flakes";
      };

      system = {
        configurationRevision = self.rev or self.dirtyRev or null;
        stateVersion = 6;
        primaryUser = "ntngel1";
      };

      security.pam.services.sudo_local.watchIdAuth = true;

      power.sleep.display = 5;

      system.defaults = {
        WindowManager.EnableTiledWindowMargins = false;
        dock = {
          persistent-apps = [
            "/System/Applications/Mail.app"
            "${pkgs.telegram-desktop}/Applications/Telegram.app"
            "/Applications/Safari.app"
            "/System/Applications/Notes.app"
            "${pkgs.spotify}/Applications/Spotify.app"
            "/Applications/Shadowrocket.app"
            "${pkgs.hoppscotch}/Applications/Hoppscotch.app"
            "${pkgs.jetbrains.idea-ultimate}/Applications/IntelliJ IDEA.app"
            "/System/Applications/Utilities/Terminal.app"
          ];
          show-recents = false;
          wvous-br-corner = 1;
        };
        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXDefaultSearchScope = "SCcf";
          FXEnableExtensionChangeWarning = false;
          FXPreferredViewStyle = "Nlsv";
          ShowPathbar = true;
        };
        controlcenter.BatteryShowPercentage = true;
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
          "com.apple.keyboard.fnState" = true;
        };
        CustomSystemPreferences = {
          "com.apple.Safari"."com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
            # Disable default screenshots
            "28" = { enabled = false; };
            "30" = { enabled = false; };
            # Enable custom clipboard screenshots
            "29" = {
              enabled = true;
              value = { parameters = [51 20 1179648]; type = "standard"; };
            };
            "31" = {
              enabled = true;
              value = { parameters = [52 21 1179648]; type = "standard"; };
            };
          };
        };
      };

      services.redis.enable = true;

      users.users.ntngel1 = {
        home = "/Users/ntngel1";
      };

      nixpkgs = {
        hostPlatform = system;
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
      };
    };

    homeconfig = { pkgs, config, ... }: {
      home.stateVersion = "25.05";
      programs.home-manager.enable = true;

      home.packages = with pkgs; [ ];

      home.file = {
        ".config/sbt/sbtopts".text = "-J-Xmx4096M -J-Xss2M";
        ".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/.ideavimrc";
        ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/.vimrc";
      };

      home.sessionVariables = {
        EDITOR = "vim";
      };

      programs.sbt.enable = true;

      programs.zsh = {
        enable = true;
        shellAliases = {
          ls = "ls -la";
          mongostage = "mongosh mongodb://10.40.0.35:27017/kinokassa";
        };
      };
    };
  in {
    darwinConfigurations = {
      # You can reuse across both computers just by calling:
      # darwin-rebuild switch --flake .#<name>
      default = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.ntngel1 = homeconfig;
          }
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "ntngel1";
              autoMigrate = true;
            };
          }
        ];
      };
    };
  };
}

