{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

outputs = inputs@{ self, home-manager, nix-darwin, nix-homebrew, mac-app-util, nixpkgs }:
let 
  configuration = {pkgs, ... }: {
      home-manager.backupFileExtension = "backup";

      environment.systemPackages =
        [
           pkgs.gemini-cli
           pkgs.vim
           pkgs.jetbrains-mono
           pkgs.telegram-desktop
           pkgs.discord-canary
           pkgs.jetbrains.idea-community
           pkgs.mkalias
           pkgs.sbt
           pkgs.nodejs
           pkgs.redis
           pkgs.mongosh
           pkgs.spotify
           pkgs.hoppscotch
           pkgs.docker
           pkgs.docker-client
           pkgs.colima
        ];

      homebrew = {
        enable = true;
	casks = [
            "logi-options+"
	];
        masApps = {
          # Shadowrocket = 932747118;
          Keynote = 409183694;
          Numbers = 409203825;
        };
        
        onActivation.cleanup = "uninstall";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      nix.enable = false;
      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;
      security.pam.services.sudo_local.watchIdAuth = true;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      power.sleep.display = 5;
      system.primaryUser = "ntngel1";
      system.defaults = {
        WindowManager.EnableTiledWindowMargins = false;
        dock.persistent-apps = [
          "/System/Applications/Mail.app"
          "${pkgs.telegram-desktop}/Applications/Telegram.app"
          "${pkgs.discord-canary}/Applications/Discord Canary.app"
          "/Applications/Safari.app"
          "/System/Applications/Notes.app"
          "${pkgs.spotify}/Applications/Spotify.app"
          "/Applications/Shadowrocket.app"
          "${pkgs.hoppscotch}/Applications/Hoppscotch.app"
          "${pkgs.jetbrains.idea-community}/Applications/IntelliJ IDEA CE.app"
          "/System/Applications/Utilities/Terminal.app"
        ];
        dock.show-recents = false;
        dock.wvous-br-corner = 1;
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.FXDefaultSearchScope = "SCcf";
        finder.FXEnableExtensionChangeWarning = false;
        finder.FXPreferredViewStyle = "Nlsv";
        finder.ShowPathbar = true;
        controlcenter.BatteryShowPercentage = true;
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
          "com.apple.keyboard.fnState" = true;
        };
        CustomSystemPreferences = {
          "com.apple.Safari" = {
            "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          };
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
              # screenshoting and saving to desktop
              "28" = { enabled = false; };
              "30" = { enabled = false; };
              # screenshoting and saving to clipboard
              "29" = {
                enabled = true;
                value = {
                  parameters = [51 20 1179648];
                  type = "standard";
                };
              };
              "31" = {
                enabled = true;
                value = {
                  parameters = [52 21 1179648];
                  type = "standard";
                };
              };
            };
          };
	};
      };
      
      services.redis.enable = true;

      users.users.ntngel1 = {
          home = "/Users/ntngel1";
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnsupportedSystem = true;
};
    homeconfig = {pkgs, config, ... }: {
        home.stateVersion = "25.05";
	programs.home-manager.enable = true;

	home.packages = with pkgs; [];
	home.file = {
            ".config/sbt/sbtopts".text = "-J-Xmx4096M -J-Xss2M";
            ".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/.ideavimrc";

            ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/.vimrc";
	};
	home.sessionVariables = {
            EDITOR = "vim";
            GOOGLE_CLOUD_PROJECT = "midyear-node-467706-e4";
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
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#macbook
    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
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
}
