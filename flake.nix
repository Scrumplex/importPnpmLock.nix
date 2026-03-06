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
      legacyPackages = forSystems ({ pkgs, ... }: import ./. { inherit pkgs; });

      formatter = forSystems ({ pkgs, ... }: pkgs.nixfmt-tree);

      checks = forSystems (
        { pkgs, ourPackages, ... }:
        {
          vencord = pkgs.callPackage ./checks/vencord.nix {
            inherit (ourPackages) importPnpmLock iplConfigHook;
          };
        }
      );
    };
}
