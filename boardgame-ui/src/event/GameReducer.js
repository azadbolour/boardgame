
import {mkEmptyGame} from '../domain/Game';
import ActionTypes from './GameActionTypes';
import {mkGameEventHandler} from "./GameEventHandler";
import {stringify} from "../util/Logger"
import {emptyAuxGameData} from "../domain/AuxGameData";

export const mkGameReducer = function(gameParams, gameService) {

  const dispatcher = mkGameEventHandler(gameService);
  const emptyGame = mkEmptyGame(gameParams);
  const initialState = {
    game: emptyGame,
    auxGameData: emptyAuxGameData(),
    // The status of the last attempted action.
    userMessage: "",
    // The last action attempted.
    action: null // TODO. null? smell?
  };

  console.log(`initial state in reducer: ${stringify(initialState)}`);

  // TODO. Should the status be reset at the beginning of each action?
  // It should be reset in the handler.
  // TODO. Maybe get a brand new event handler each time?
  // TODO. Maybe the handler should always al the state that should be stored.

  const reducer = function(state = initialState, action) {

    console.log(`reduce call - state: ${stringify(state)}, action: ${stringify(action)}`);

    // Every action changes the game as a whole. Factor out the state change.

    // TODO. Result from handler is dropped on the floor. It is a response. Should we keep track?
    switch (action.type) {
      case ActionTypes.START:
      case ActionTypes.MOVE:
      case ActionTypes.REVERT_MOVE:
      case ActionTypes.COMMIT_PLAY:
      case ActionTypes.REVERT_PLAY:
      case ActionTypes.SWAP:
        const promise = dispatcher(action);
        console.log(`GameReducer - returned promise: ${stringify(promise)}`);
        promise.then(result => {
            return {
              game: result.game,
              auxGameData: result.auxGameState,
              userMessage: result.userMessage,
              action: action
            }
        }).catch(error => {
          return {
            ...state,
            status: stringify(error),
            action: action
          }
        });
        break;
      default:
        return state;
    }
  };

  return reducer
};

// switch (action.type) {
//   case ActionTypes.START:
//     handler.handleStart(action.gameParams);
//     break;
//   case ActionTypes.MOVE:
//     handler.handleMove(action.move);
//     break;
//   case ActionTypes.REVERT_MOVE:
//     handler.handleRevertMove(action.piece);
//     break;
//   case ActionTypes.COMMIT_PLAY:
//     handler.handleCommitPlayAndGetMachinePlay();
//     break;
//   case ActionTypes.REVERT_PLAY:
//     handler.handleRevertPlay();
//     break;
//   // case ActionTypes.END:
//   //   return handler.handleEnd();
//   case ActionTypes.SWAP:
//     handler.handleSwapAndGetMachinePlay(action.piece);
//     break;
//   default:
//     return state;
// }