/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */



console.log('hello');
gamePlayer = process.env['GAME_PLAYER_NAME'];
if (!gamePlayer)
  gamePlayer = "John";
console.log(`${gamePlayer}`);
