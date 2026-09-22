# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  fetchFromGitHub,
  importPnpmLock,
  iplConfigHook,
  lib,
  makeShellWrapper,
  nodejs,
  pnpm_12,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "git-wt";
  version = "0.0.9-unstable-2026-09-02";

  src = fetchFromGitHub {
    owner = "zkochan";
    repo = "git-wt";
    rev = "e3d869696bfc6805d5b83e5fa8be18a147d4a47a";
    hash = "sha256-7xoFYLN2lebL654vEWFBJSlA3EWDaP+942NyzYrCvwQ=";
  };

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

    touch pnpm-workspace.yaml

    pnpm deploy $out/lib/git-wt --reporter append-only --loglevel debug

    makeWrapper ${lib.getExe nodejs} $out/bin/git-wt \
      --add-flags "$out/lib/git-wt/lib"

    runHook postInstall
  '';

  __structuredAttrs = true;

  meta = {
    license = lib.licenses.mit;
    mainProgram = "git-wt";
  };
})
