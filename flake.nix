{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { nixpkgs, systems, ... }:
    let
      forSystems =
        attrs:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          attrs {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      legacyPackages = forSystems ({ pkgs, ... }: import ./. { inherit pkgs; });

      formatter = forSystems ({ pkgs, ... }: pkgs.nixfmt-tree);
    };
}
