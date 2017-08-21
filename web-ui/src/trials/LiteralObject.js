/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */



const x = {
  foo: function() {
    this.bar();
  },

  bar: function() {
    console.log('bar');
  }
}

x.foo();