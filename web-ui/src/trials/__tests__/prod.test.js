/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

'use strict';

test('1 * 2 = 2', () => {
  const prod = require('../Prod');
  expect(prod(1, 2)).toBe(2);
});
