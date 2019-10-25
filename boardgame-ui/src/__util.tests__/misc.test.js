/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import {zipWith} from "../util/MiscUtil";
import {stringify} from "../util/Logger";

test('zip', () => {
  let arr1 = [1, 2];
  let arr2 = [100, 200];

  let zipped = zipWith(arr1, arr2, (a, b) => a + b);
  console.log(`${stringify(zipped)}`);

  let rows = [[1, 2], [100, 200], [1000, 2000]];

  let reduced = rows.reduce(function(cols, row) {
    return zipWith(cols, row, function(col, value) {
      col.push(value);
      return col;
    })
  }, [[], []]);
  console.log(`${stringify(reduced)}`);
});