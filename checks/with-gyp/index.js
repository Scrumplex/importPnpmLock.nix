// SPDX-FileCopyrightText: 2026 Sefa Eyeoglu <contact@scrumplex.net>
//
// SPDX-License-Identifier: MIT

import RE2 from "re2";

import p from "./package.json" with { type: "json" };

const main = () => {
    const pattern = new RE2(/\d+\.\d+\.\d+/);
    console.log(pattern);
    console.log(p.version.match(pattern));
};

main();
