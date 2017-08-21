/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * Types of actions triggered by user interactions. Used as
 * unique names for actions and matched by interested listeners
 * to dispatched actions.
 */
const ActionTypes = {
  // UI-triggered actions.
  START: 'START',
  MOVE: 'MOVE',
  REVERT_MOVE: 'REVERT_MOVE',
  COMMIT_PLAY: 'COMMIT_PLAY',
  REVERT_PLAY: 'REVERT_PLAY',
  END: 'END',
  SWAP: 'SWAP',
};

export default ActionTypes;