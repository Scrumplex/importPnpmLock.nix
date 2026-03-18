# SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
#
# SPDX-License-Identifier: MIT

{
  self,
  reuse,
  runCommand,
}:
runCommand "ipl-check-reuse"
  {
    nativeBuildInputs = [ reuse ];
  }
  ''
    pushd "${self}"
    reuse lint
    popd
    touch "$out"
  ''
