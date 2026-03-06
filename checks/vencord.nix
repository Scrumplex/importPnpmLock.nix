{
  fetchFromGitHub,
  git,
  nodejs,
  pnpm_10,
  iplConfigHook,
  importPnpmLock,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vencord";
  version = "1.14.4";

  src = fetchFromGitHub {
    owner = "Vendicated";
    repo = "Vencord";
    tag = "v${finalAttrs.version}";
    hash = "sha256-B+A3ArypZBbgcRBwrW5lr6JEjiTNrKlLWMzX9x3rKzM=";
  };

  mitmCache = importPnpmLock {
    lockFile = "${finalAttrs.src}/pnpm-lock.yaml";
    manualEntries = {
      "gifenc@https://codeload.github.com/mattdesl/gifenc/tar.gz/64842fca317b112a8590f8fef2bf3825da8f6fe3" =
        "sha256-Tw2j23uifvrOlF2DAeitFNcV9MSGxG6Nk+GmOYB/EEU=";
    };
  };

  nativeBuildInputs = [
    git
    nodejs
    iplConfigHook
    pnpm_10
  ];

  env = {
    VENCORD_REMOTE = "${finalAttrs.src.owner}/${finalAttrs.src.repo}";
    VENCORD_HASH = "${finalAttrs.version}";
  };

  buildPhase = ''
    runHook preBuild

    pnpm run build \
      -- --standalone --disable-updater

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r dist/ $out
    cp package.json $out # Presence is checked by Vesktop.

    runHook postInstall
  '';

})
