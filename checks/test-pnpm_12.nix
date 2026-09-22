# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  importPnpmLock,
  iplConfigHook,
  lib,
  makeShellWrapper,
  nodejs,
  path,
  pnpm_12,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pnpm-test";
  inherit (pnpm_12) version;

  src = "${path}/pkgs/test/pnpm/pnpm_12_v4/src";

  mitmCache = importPnpmLock {
    inherit (finalAttrs) pname version;
    lockFile = "${finalAttrs.src}/pnpm-lock.yaml";
  };

  nativeBuildInputs = [
    makeShellWrapper
    nodejs
    pnpm_12
    iplConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/lib/pnpm-12-test dist/index.js

    makeWrapper ${lib.getExe nodejs} $out/bin/pnpm-12-test \
      --add-flags "$out/lib/pnpm-12-test"

    runHook postInstall
  '';

  __structuredAttrs = true;

  meta = {
    license = lib.licenses.mit;
    mainProgram = "pnpm-12-test";
  };
})
