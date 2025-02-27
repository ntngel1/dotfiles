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
      users.users.ntngel1 = {
          home = "/Users/ntngel1";
      };

      environment.systemPackages =
        [
           pkgs.neovim
           pkgs.alacritty
           pkgs.telegram-desktop
           pkgs.discord
           pkgs.jetbrains.idea-community
           pkgs.mkalias
           pkgs.sbt
        ];

      homebrew = {
        enable = true;
        masApps = {
          Shadowrocket = 932747118;
        };
        
        onActivation.cleanup = "uninstall";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };


      nix.enable = false;
      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      system.defaults = {
        dock.persistent-apps = [
          "/System/Applications/Mail.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
          "${pkgs.discord}/Applications/Discord.app"
          "${pkgs.jetbrains.idea-community}/Applications/IntelliJ IDEA CE.app"
        ];
        dock.show-recents = false;
        dock.wvous-br-corner = 1;
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.FXDefaultSearchScope = "SCcf";
        finder.FXEnableExtensionChangeWarning = false;
        finder.FXPreferredViewStyle = "Nlsv";
        finder.ShowPathbar = true;
        NSGlobalDomain = {
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
        };
      };
      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
};
    homeconfig = {pkgs, ... }: {
        home.stateVersion = "25.05";
	programs.home-manager.enable = true;

	home.packages = with pkgs; [];
	home.sessionVariables = {
            EDITOR = "nvim";
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
