
/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

// Auxiliary data needed to render the game.

export const mkAuxGameData = function(wordsPlayed) {
  let _wordsPlayed = wordsPlayed;

  return {
    get wordsPlayed() { return _wordsPlayed; },

    pushWordPlayed(word, playerName) {
      let wordPlayed = {
        word: word,
        playerName: playerName
      };
      _wordsPlayed.push(wordPlayed);
    },

    resetWordsPlayed() {
      _wordsPlayed = [];
    }
  }
};

export const emptyAuxGameData = function() {return mkAuxGameData([])};
