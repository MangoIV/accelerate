{
  description = "accelerate - high-performance parallel arrays for Haskell";

  nixConfig = {
    allow-import-from-derivation = true;
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    extra-substituters = "https://nix-community.cachix.org";
    bash-prompt = "\\[\\e[34;1m\\]accelerate ~ \\[\\e[0m\\]";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    dream2nix = {
      url = "github:nix-community/dream2nix"; # "/home/mangoiv/Devel/dream2nix"; #
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    dream2nix,
    pre-commit-hooks,
    flake-parts,
    nixpkgs,
  }:
    flake-parts.lib.mkFlake {inherit inputs self;} {
      imports = [
        inputs.pre-commit-hooks.flakeModule
        inputs.dream2nix.flakeModuleBeta
      ];
      systems =
        if builtins.hasAttr "currentSystem" builtins
        then [builtins.currentSystem]
        else nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        pkgs,
        config,
        ...
      }: {
        dream2nix.inputs."accelerate" = {
          source = ./.;
          projects = {
            accelerate = {
              name = "accelerate";

              subsystem = "haskell";
              translator = "stack-lock";
              relPath = "";
              /*
              subsystemInfo.compilers = [
                { name = "ghc" ; version = [8 10 7]; }
                { name = "ghc" ; version = [9 0 2]; }
              ];
              */
            };
          };
        };

        pre-commit.settings = {
          src = ./.;
          hooks = {
            cabal-fmt.enable = true;
            fourmolu.enable = false;
            hlint.enable = false;

            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        devShells.tooling = pkgs.mkShell {
          shellHook = config.pre-commit.installationScript;
        };

        packages = {
          inherit (config.dream2nix.outputs.accelerate.packages) accelerate;
        };
      };
    };
}
