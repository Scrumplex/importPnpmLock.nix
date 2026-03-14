# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

# shellcheck shell=bash

iplConfigHook() {
    echo "Executing iplConfigHook"

    if ! command -v "pnpm" &> /dev/null; then
      echo "Error: 'pnpm' binary not found in PATH. Consider adding 'pkgs.pnpm' to 'nativeBuildInputs'." >&2
      exit 1
    fi

    export npm_config_arch="@npmArch@"
    export npm_config_platform="@npmPlatform@"

    # If the packageManager field in package.json is set to a different pnpm version than what is in nixpkgs,
    # any pnpm command would fail in that directory, the following disables this
    pushd /
    pnpm config set manage-package-manager-versions false
    popd

    # Prevent hard linking on file systems without clone support.
    # See: https://pnpm.io/settings#packageimportmethod
    pnpm config set package-import-method clone-or-copy

    # mitm-cache doesn't set a full URL and pnpm defaults to https. Force it to treat it as a plain text proxy
    pnpm config set https-proxy "http://$https_proxy"

    runHook prePnpmInstall

    if ! pnpm install \
        --ignore-scripts \
        "${pnpmInstallFlags[@]}" \
        --frozen-lockfile
    then
        echo
        echo "ERROR: pnpm failed to install dependencies"
        echo

        exit 1
    fi

    echo "Patching scripts"

    patchShebangs node_modules/{*,.*}

    echo "Finished iplConfigHook"
}

postConfigureHooks+=(iplConfigHook)

