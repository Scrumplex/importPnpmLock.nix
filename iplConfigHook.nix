# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  makeSetupHook,
  stdenvNoCC,
  mitm-cache,
}:
makeSetupHook {
  name = "import-pnpm-lock-config-hook";
  propagatedBuildInputs = [
    mitm-cache
  ];
  substitutions = {
    npmArch = stdenvNoCC.targetPlatform.node.arch;
    npmPlatform = stdenvNoCC.targetPlatform.node.platform;
  };
} ./config-hook.sh
