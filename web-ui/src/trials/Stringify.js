/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


const GameParams = require('../domain/GameParams');

let gameParams = GameParams.defaultParams();
console.log(`${JSON.stringify(gameParams)}`);
