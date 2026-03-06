{
  pkgs ? import <nixpkgs> { },
}:
{
  importPnpmLock = pkgs.callPackage ./importPnpmLock.nix { };
  iplConfigHook = pkgs.callPackage ./iplConfigHook.nix { };
}
