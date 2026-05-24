# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  lib,
  runCommand,
  yj,
  mitm-cache,
  config,
}:
{
  pname,
  version,
  lockFile,
  manualEntries ? { },
}:
let
  supportedLockFileVersions = [
    "9.0"
  ];

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

  applyMirrorToUrl =
    url:
    let
      mUrl = builtins.match "(.+)://([^/]+)/(.+)" url;
      scheme = builtins.elemAt mUrl 0;
      host = builtins.elemAt mUrl 1;
      path = builtins.elemAt mUrl 2;
    in
    if config.npmRegistryOverrides ? "${host}" then
      "${scheme}://${config.npmRegistryOverrides."${host}"}/${path}"
    else
      url;

  data = importYAML lockFile;

  mapPackageToMitmCacheEntry =
    name: package:
    let
      url = applyMirrorToUrl (urlFromName name);
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

  # directory resolution does not need any fetching
  filterPackageEntry = _: package: (package.resolution or { }).type or null != "directory";

  lockFileVersion = data.lockfileVersion or null;
in
assert lib.assertMsg (lockFileVersion != null) ''
  lockFile ${lockFile} does not look like a supported lock file.
  Unable to read lock file version.
'';
assert lib.assertMsg (builtins.elem lockFileVersion supportedLockFileVersions) ''
  File ${lockFile} is not a supported lock file.

  Supported versions are ${lib.concatStrings supportedLockFileVersions}

  Found version ${lockFileVersion}
'';
assert lib.assertMsg (data ? packages) ''
  File ${lockFile} does not contain a list of locked packages.
  Is it a valid lock file?
'';
mitm-cache.fetch {
  name = "${pname}-pnpm-mitm-cache-${version}";
  data = lib.mapAttrs' mapPackageToMitmCacheEntry (lib.filterAttrs filterPackageEntry data.packages);
}
