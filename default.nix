{
  pkgs ? import <nixpkgs> { },
}:
{
  importPnpmLock = pkgs.callPackage ./importPnpmLock.nix { };
}
