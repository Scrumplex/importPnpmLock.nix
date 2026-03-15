# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      forSystems =
        attrs:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          attrs {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
            ourPackages = self.legacyPackages.${system};
          }
        );
    in
    {
      formatter = forSystems ({ pkgs, ... }: pkgs.nixfmt-tree);
      devShells = forSystems (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [ reuse ];
          };
        }
      );

      overlays.default = final: _: import ./. { pkgs = final; };

      legacyPackages = forSystems ({ pkgs, ... }: import ./. { inherit pkgs; });

      checks = forSystems (
        { pkgs, ourPackages, ... }:
        {
          vencord = pkgs.callPackage ./checks/vencord.nix {
            inherit (ourPackages) importPnpmLock iplConfigHook;
          };
          reuse = pkgs.callPackage ./checks/reuse.nix {
            inherit self;
          };
        }
      );
    };
}
