# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  pkgs ? import <nixpkgs> { },
}:
{
  importPnpmLock = pkgs.callPackage ./importPnpmLock.nix { };
  iplConfigHook = pkgs.callPackage ./iplConfigHook.nix { };
}
