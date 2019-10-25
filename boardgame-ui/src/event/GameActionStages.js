/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameActionStages
 */

/**
 * Stages of an action.
 */
const ActionStages = {
  /**
   * Change requested by not yet completed.
   */
  CHANGE_REQUEST: 'CHANGE_REQUEST',

  /**
   * Change completed successfully.
   */
  CHANGE_SUCCESS: 'CHANGE_SUCCESS',

  /**
   * Change failed.
   */
  CHANGE_FAILURE: 'CHANGE_FAILURE'
};

export default ActionStages;