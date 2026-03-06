# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  lib,
  runCommand,
  yj,
  mitm-cache,
}:
{
  pname,
  version,
  lockFile,
  manualEntries ? { },
}:
let
  importYAML =
    file:
    let
      json = runCommand "${pname}-pnpm-lock.json" { } ''
        ${yj}/bin/yj < ${file} > $out
      '';
    in
    lib.importJSON json;

  splitName = builtins.match "^(@?[^@]+)@(.+)$";

  urlFromName =
    name:
    let
      c = splitName name;
      scopedName = builtins.head c;
      version = lib.last c;
      versionIsUrl = lib.hasPrefix "http" version;
      packageName = lib.last (lib.splitString "/" scopedName);
    in
    if versionIsUrl then
      version
    else
      "https://registry.npmjs.org/${scopedName}/-/${packageName}-${version}.tgz";

  data = importYAML lockFile;

  mapPackageToMitmCacheEntry =
    name: package:
    let
      url = urlFromName name;
      integrity = (package.resolution or { }).integrity or manualEntries.${name} or null;
    in
    assert lib.assertMsg (integrity != null) ''
      Package ${name} doesn't have an integrity entry.

      To fix this, add a manual entry using

        importPnpmLock {
          lockFile = ${lockFile};
          manualEntries = {
            "${name}" = "";
          };
        }
    '';
    lib.nameValuePair url {
      hash = integrity;
    };
in
mitm-cache.fetch {
  name = "${pname}-pnpm-mitm-cache-${version}";
  data = lib.mapAttrs' mapPackageToMitmCacheEntry data.packages;
}
