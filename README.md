<!--
SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>

SPDX-License-Identifier: MIT
-->

# importPnpmLock.nix

Nix tooling to import `pnpm-lock.yaml`s so you can build reproducible Node.js
packages without package manager regrets.

## Importing

### The flakey way

If you use Flakes, then you should know most of what comes next.

Add importPnpmLock as an input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    importPnpmLock = {
      url = "git+https://tangled.org/scrumplex.net/importPnpmLock.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

After that you can either consume the overlay `importPnpmLock.overlays.default`
or directly add `importPnpmLock.legacyPackages.<system>.importPnpmLock` and
`importPnpmLock.legacyPackages.<system>.iplConfigHook` to your derivation
inputs.

### The classic way

No matter if you use niv, npins or god forbid nix channels, you can just fetch
this repo as a tarball from
<https://tangled.org/scrumplex.net/importPnpmLock.nix/archive/main> and consume it.

Below are some examples using npins for convenience:

```sh
# npins - as a tarball
$ npins add tarball https://tangled.org/scrumplex.net/importPnpmLock.nix/archive/main --name importPnpmLock

# npins - as a git repo (bonus: pins tags, instead of latest commit!)
$ npins add git https://tangled.org/scrumplex.net/importPnpmLock.nix --name importPnpmLock
```

After adding importPnpmLock.nix to npins, you can use it like this:

```nix
let
  sources = import ./npins;

  pkgs = import sources.nixpkgs { };

  # Use ipl attrs directly
  ipl = import sources.importPnpmLock { inherit pkgs; };

  # Use it as an overlay
  pkgsWithIPL = import sources.nixpkgs {
    overlays = [
      (final: _: import ../Projects/importPnpmLock.nix { pkgs = final; })
    ];
  };
in
  # do something
```

## Usage

This repository exposes two outputs.

1. `importPnpmLock` - the actual function that generates a reproducible cache
   of all dependencies defined in `pnpm-lock.yaml`
2. `iplConfigHook` - the configuration hook that runs `pnpm install` with some
   fluff to make it all work in your actual derivation

An example is best suited to show how these work together:

```nix
{
  importPnpmLock,
  iplConfigHook,
  pnpm_10,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "my-package";
  version = "1.14.4";

  src = ./.;

  # iplConfigHook uses the great mitm-cache under the hood, which is why this
  # attribute has to be called mitmCache
  mitmCache = importPnpmLock {
    # pname and version are required to to make it look nicer
    inherit (finalAttrs) pname version;

    # Path to the lock file. This causes IFD!
    lockFile = ./pnpm-lock.yaml;

    # Tarballs and Git dependencies don't have hashes, that's why those need to
    # be specified manually :/
    manualEntries = {
      "my-weird-unstable-package@https://codeload.github.com/copilot/my-weird-unstable-package/tar.gz/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" =
        "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  nativeBuildInputs = [
    # iplConfigHook hooks into configurePhase to prepare the pnpm workspace
    iplConfigHook
    # pnpm needs to be added explicitly!
    pnpm_10
  ];


  # Optionally define additional flags for pnpm install
  #  pnpmInstallFlags = [
  #    "--shamefully-hoist"
  #  ];

  buildPhase = ''
    runHook preBuild

    # Optionally run install scripts of installed packages
    # If scripts are only needed to run for the final package, consider using `pnpm deploy` in install phase instead
    # --reporter append-only improves log output significantly
    #  pnpm rebuild --pending --reporter append-only # --loglevel debug

    # or any other script
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Or anything else really
    cp -r dist/ $out

    runHook postInstall
  '';
})
```

## Caveats

- IFD - As Nix does not support importing/reading YAML files natively, we have
  to convert `pnpm-lock.yaml` files to JSON so we can parse them. This introduces
  a performance loss that other places can explain in much more detail.
- Manual hashes for tarballs - `pnpm-lock.yaml` does not store hashes for
  tarballs, and by extension Git sources. That means those will still need to be
  specified by hand, making automated updates by the likes of Renovate or
  dependabot more cumbersome.
- Huge cache - As the parser is very dumb, it will always create a cache for
  the whole lockfile, even if you just want to build a tiny component of a huge
  monorepo. On the other hand, there will only be a single cache for the whole
  monorepo! There may be ways to reduce the cache in the future.

## Examples

Take a look at [`checks/vencord.nix`](checks/vencord.nix) and
[`checks/with-gyp/default.nix`](checks/with-gyp/default.nix) for some *real
world* examples.
