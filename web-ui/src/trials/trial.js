/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


const MockApi = require("../api/MockApi");
const GameParams = require("../domain/GameParams");

import {GameParamsConverter} from '../api/Converters';

let mock = new MockApi();
let gameParams = GameParams.defaultParams();
let paramsDto = GameParamsConverter.toJson(gameParams);
let gameId = mock.startGame(paramsDto, [], [], []);
console.log(`${JSON.stringify(gameId)}`);