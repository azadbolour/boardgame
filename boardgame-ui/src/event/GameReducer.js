
import {mkEmptyGame} from '../domain/Game';
import ActionTypes from './GameActionTypes';
import {mkGameEventHandler} from "./GameEventHandler";

// TODO. after each call: state.game = handler.game.
// TODO. The previous state of the game is in the state. Get it and send to handler.

export const mkGameReducer = function(gameParams, gameService) {
  const handler = mkGameEventHandler(gameService);
  const reducer = function(state = mkEmptyGame(gameParams), action) {
    switch (action.type) {
      case ActionTypes.START:
        let result = handler.handleStart(action.gameParams);
        return result;
      case ActionTypes.MOVE:
        return handler.handleMove(action.move);
      case ActionTypes.REVERT_MOVE:
        return handler.handleRevertMove(action.piece);
      case ActionTypes.COMMIT_PLAY:
        return handler.handleCommitPlayAndGetMachinePlay();
      case ActionTypes.REVERT_PLAY:
        return handler.handleRevertPlay();
      // case ActionTypes.END:
      //   return handler.handleEnd();
      case ActionTypes.SWAP:
        return handler.handleSwapAndGetMachinePlay(action.piece);
      default:
        return state;
    }
  };

  return reducer
};