{
  description = "Vibe coding environment with essential development tools";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      home-manager,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        tools = with pkgs; [
          bat
          curl
          diffutils
          direnv
          duckdb
          fd
          fish
          git
          gnused
          htop
          jq
          just
          neovim
          nload
          postgresql
          ripgrep
          rustup
          sqlite-interactive
          terraform # "unfree", requires flag above
          tmux
          tree
          unzip
          uv
          watch
          zip
        ];
        home-manager-bin = "${home-manager.packages.${system}.default}/bin/home-manager";
      in
      {
        # Apps that can be run with 'nix run .#{name}'
        apps = {
          home-manager = {
            type = "app";
            program = home-manager-bin;
            meta = {
              description = "Home Manager configuration management tool";
            };
          };
        };

        homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              home = {
                packages = tools;
                sessionPath = [
                  "$HOME/.cargo/bin"
                  "$HOME/.local/bin"
                  "$HOME/bin"
                ];
                sessionVariables = {
                  LESS = "-FRS"; # Don't page if <1 screen, show colors, don't wrap
                  PYTHONDONTWRITEBYTECODE = "1";
                };
                shellAliases = {
                  fd = "fd --hidden";
                };
                stateVersion = "24.11";
                username = "viber";
              };
              programs = {
                direnv = {
                  enable = true;
                  nix-direnv.enable = true; # Automatically cache envs: https://github.com/nix-community/nix-direnv
                };
                eza = {
                  enable = true;
                  extraOptions = [
                    "--all"
                    "--git"
                    "--group-directories-first"
                    "--header"
                    "--icons"
                    "--sort=Name" # [A, B, a]; not [A, a, B]
                  ];
                };
                fish = {
                  enable = true;
                  shellInit = ''
                    fish_vi_key_bindings
                    set -gx UV_LINK_MODE copy
                  '';
                };
                home-manager.enable = true;
                neovim = {
                  defaultEditor = true;
                  enable = true;
                  extraPackages = [
                    pkgs.luajit
                    pkgs.luarocks
                  ];
                  withNodeJs = true;
                  withPython3 = true;
                  withRuby = false;
                };
              };
              xdg.enable = true; # Set XDG_* env vars
            }
          ];
        };

        packages = {
          vibins = pkgs.buildEnv {
            name = "vibins";
            paths = tools;
          };
        };

        packages.default = self.packages.${system}.vibins;
      }
    );
}
