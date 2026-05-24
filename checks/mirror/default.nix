# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  importPnpmLock,
  testers,
}:
let
  mitmCache = importPnpmLock {
    pname = "ipl-mirror-test";
    version = "0.0.0";
    lockFile = ./pnpm-lock.yaml;
  };
in
testers.testEqualContents {
  assertion = "NPM URLs are replaced by my-mirror.local/npm-registry";
  expected = ./expected.json;
  actual = mitmCache.data;
}
