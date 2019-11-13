/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * Action types used to trigger state changes.
 */
export const GameActionTypes = {

  // Start a game.
  START_INIT: 'START_INIT',
  START_SUCCESS: 'START_SUCCESS',
  START_FAILURE: 'START_FAILURE',

  // Move a piece.
  MOVE_INIT: 'MOVE_INIT',
  MOVE_SUCCESS: 'MOVE_SUCCESS',
  MOVE_FAILURE: 'MOVE_FAILURE',

  // Revert move a piece.
  REVERT_MOVE_INIT: 'REVERT_MOVE_INIT',
  REVERT_MOVE_SUCCESS: 'REVERT_MOVE_SUCCESS',
  REVERT_MOVE_FAILURE: 'REVERT_MOVE_FAILURE',

  // Commit a completed word play.
  COMMIT_PLAY_INIT: 'COMMIT_PLAY_INIT',
  COMMIT_PLAY_SUCCESS: 'COMMIT_PLAY_SUCCESS',
  COMMIT_PLAY_FAILURE: 'COMMIT_PLAY_FAILURE',

  // Undo a;; moves in the current as yet uncommitted word play.
  REVERT_PLAY_INIT: 'REVERT_PLAY_INIT',
  REVERT_PLAY_SUCCESS: 'REVERT_PLAY_SUCCESS',
  REVERT_PLAY_FAILURE: 'REVERT_PLAY_FAILURE',

  // Swap an existing tray piece for a new tray piece allocated by the system.
  SWAP_INIT: 'SWAP_INIT',
  SWAP_SUCCESS: 'SWAP_SUCCESS',
  SWAP_FAILURE: 'SWAP_FAILURE'

  // END: 'END'
};

export const startFailure = function(actionType) { return actionType === GameActionTypes.START_FAILURE };

export const startCompletion = function(ok) {
  return ok ? GameActionTypes.START_SUCCESS : GameActionTypes.START_FAILURE;
};