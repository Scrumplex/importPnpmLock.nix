# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  importPnpmLock,
  iplConfigHook,
  lib,
  makeBinaryWrapper,
  nodejs,
  pnpm_10,
  python3Minimal,
  stdenv,
  versionCheckHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "with-gyp";
  version = (lib.importJSON ./package.json).version;

  src = ./.;

  mitmCache = importPnpmLock {
    inherit (finalAttrs) pname version;
    lockFile = ./pnpm-lock.yaml;
  };

  nativeBuildInputs = [
    iplConfigHook
    nodejs
    pnpm_10
    python3Minimal
    makeBinaryWrapper
  ];

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  # node-gyp would otherwise struggle to find node headers
  env.npm_config_nodedir = nodejs;

  dontBuild = true;
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    pnpm deploy --filter=with-gyp... $out/lib/with-gyp --reporter append-only --loglevel debug

    makeWrapper ${lib.getExe nodejs} $out/bin/re2-test \
      --add-flags "$out/lib/with-gyp"

    runHook postInstall
  '';

  meta.mainProgram = "re2-test";
})
