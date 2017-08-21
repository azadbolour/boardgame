/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

const validUrl = require('valid-url');

let good = "http://181.181.181.181:1111/boardgame";
console.log(validUrl.isWebUri(good));
let bad = "something";
console.log(validUrl.isWebUri(bad));