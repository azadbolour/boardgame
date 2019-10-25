/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


test('add to undefined', () => {
  let x = 1;
  let y = undefined;
  let sum = x + y; // NaN - not an exception.
  console.log(sum);
});