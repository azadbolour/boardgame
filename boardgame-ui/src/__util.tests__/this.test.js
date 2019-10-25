/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


test('this', () => {
  let f = function(x) {
    return {
      x: x,
      y: 1,
      func: function() {
        return this.x;
      },
      func1: () => {this.y + 1 + this.x}
    }
  };

  let obj = f(2);
  console.log(`${obj.x} ${obj.y}`);
  let result = obj.func1(); // Fails - this will be undefined.
  console.log(result);
});