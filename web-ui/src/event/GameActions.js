/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameActions
 */

import GameActionTypes from './GameActionTypes';
import {gameDispatcher} from './GameDispatcher';

/**
 * Actions are top-level functions notifying the application
 * of user interactions. Actions use the React dispatcher to
 * notify the parts of the system that need to respond to
 * user interactions. The names should be self-explanatory
 * for the board game.
 */
const Actions = {
  start(gameParams) {
    gameDispatcher.dispatch({
      type: GameActionTypes.START,
      gameParams: gameParams
    });
  },

  move(move) {
    gameDispatcher.dispatch({
      type: GameActionTypes.MOVE,
      move: move
      });
  },

  revertMove(piece) {
    gameDispatcher.dispatch({
      type: GameActionTypes.REVERT_MOVE,
      piece: piece
    });
  },

  revertPlay() {
    gameDispatcher.dispatch({
      type: GameActionTypes.REVERT_PLAY
    });

  },

  commitPlay() {
    gameDispatcher.dispatch({
      type: GameActionTypes.COMMIT_PLAY
    });
  },

  // end() {
  //   gameDispatcher.dispatch({
  //     type: GameActionTypes.END
  //   });
  // },

  swap(piece) {
    gameDispatcher.dispatch({
      type: GameActionTypes.SWAP,
      piece: piece
    });
  }
}

export default Actions;