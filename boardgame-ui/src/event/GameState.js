/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * The state of the needed by components for rendering.
 *
 * @param game The game domain object.
 * @param auxGameData Additional information about the state of the game.
 * @param opStatus Message about the last operation.
 * @param actionType Type of the last operation.
 */
export const mkGameState = function(game, auxGameData, opStatus, actionType) {
  return {
    game: game,
    auxGameData: auxGameData,
    opStatus: opStatus,
    actionType: actionType
  }
};
