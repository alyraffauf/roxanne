{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ryantm/agenix";
    };

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/master";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {self, ...}: let
    allSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    forAllSystems = f:
      self.inputs.nixpkgs.lib.genAttrs allSystems (system:
        f {
          pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
  in {
    devShells = forAllSystems ({pkgs}: {
      default = pkgs.mkShell {
        packages =
          (with pkgs; [
            alejandra
            bash-language-server
            git
            nh
            nix-update
            nixd
            nodePackages.prettier
            rubocop
            shellcheck
            shfmt
            nodePackages.prettier
            rubocop
          ])
          ++ [
            self.inputs.agenix.packages.${pkgs.system}.default
          ];

        shellHook = ''
          export FLAKE="."
        '';
      };
    });

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    nixosConfigurations.roxanne = self.inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit self;};

      modules = [
        ./configuration.nix
        self.inputs.agenix.nixosModules.default
        self.inputs.home-manager.nixosModules.home-manager

        {
          home-manager = {
            backupFileExtension = "backup";
            extraSpecialArgs = {inherit self;};
            useGlobalPkgs = true;
            useUserPackages = true;
          };

          nixpkgs = {
            config.allowUnfree = true;
          };
        }
      ];
    };
  };
}
