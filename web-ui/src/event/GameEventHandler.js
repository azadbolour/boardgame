/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {convertResponse} from "../util/MiscUtil";
import ActionTypes from './GameActionTypes';
import ActionStages from './GameActionStages';
import {mkEmptyGame} from '../domain/Game';
import GameParams from '../domain/GameParams';
import {playPiecesWord} from '../domain/PlayPiece';
import * as PlayPiece from '../domain/PlayPiece';
import {emptyAuxGameData} from '../domain/AuxGameData';
import * as PointValue from '../domain/PointValue';


/**
 * Factory function for handler of events raised by game actions
 * (using the javascript module pattern).
 *
 * The event handler returned by this factory function is
 * registered with the game dispatcher to receive notifications
 * of user interactions and perform the desired operations,
 * manipulating the current game as required.
 *
 * Parts of the application that need to respond to the final
 * disposition of the game after the operation is completed
 * register observers with the event handler, and are notified
 * when an action is completed. The game event handler keeps
 * two state variables '_game' and '_status', and transmits
 * these to all registered observers. The _game variable represents
 * the state of the game after the operation is completed. The _status
 * variable is a textual representation of the success/failure
 * of the last operation.
 *
 * @param gameService A wrapper for the game API encapsulating
 *   the machine's representation of the game and the implementation
 *   of the machine's plays.
 *
 * @return Returns an object with three properties: the handler,
 *    and register and unregister functions for observers of
 *    changes to the game.
 */
export const mkGameEventHandler = function(gameService) {
  let _gameService = gameService;
  let _game = undefined;
  let _status = undefined;
  let _auxGameData = emptyAuxGameData();
  let _changeObservers = [];

  const OK = "OK";
  const unrecoverableErrorMessage = "we are sorry - the system encountered an unrecoverable error - and had to stop the game - ";

  const registerChangeObserver = function(observer) {
    // Yes - function references can be compared as references.
    if (!_changeObservers.find((obs) => (obs === observer)))
      _changeObservers.push(observer);
  };

  const unregisterChangeObserver = function(observer) {
    let index = _changeObservers.findIndex((obs) => (obs === observer));
    if (index === -1)
      return;
    _changeObservers.splice(index, 1);
  };

  /**
   * For now we will not distinguish between different changes.
   * Evert change will lead to uniform action by change observers,
   * without any parameters. We do distinguish between stages of
   * a change - for async changes.
   */
  const emitChange = function(changeStage) {
    _changeObservers.forEach(
      function (observer) {
        observer(changeStage, _game, _status, _auxGameData);
      }
    );
  };

  const systemResponseType = function(response) {
    let responseType = ActionStages.CHANGE_SUCCESS;
    // Status 422 indicates a user error.
    if (!response.ok && response.status !== 422)
      responseType = ActionStages.CHANGE_FAILURE;
    return responseType;
  };

  const isUserError = (response) => response.status === 422;

  const killGame = function(message) {
    _game = _game.kill();
    _status = unrecoverableErrorMessage + message;
  };

  const revertParamsToDefault = function(gameParams) {
    let isProd = gameParams.appParams.envType === 'prod'; // TODO. Constant for prod.
    let params = isProd ? GameParams.defaultClientParams() : GameParams.defaultParams();
    return params;
  };

  const blankOutGame = function(gameParams, message) {
    let stableParams = revertParamsToDefault(gameParams);
    _game = mkEmptyGame(stableParams);
    _status = unrecoverableErrorMessage + message;
    _auxGameData = emptyAuxGameData();
  };

  /**
   * FUTURE. Convert error message to user-readable form.
   * For now good enough for beta.
   */
  const errorText = (response) => JSON.stringify(response.json);

  const noGame = () => _game === undefined || _game.terminated();

  const logNoGame = () => console.log('warning: game event handler called with no game in effect');

  let handler = {
    get game() { return _game; },

    handleStart: function(gameParams) {
      console.log(`handle start - ${stringify(gameParams)}`);
      let handler = this;
      handler.handleStartInternal(gameParams).then(response => {
        if (!response.ok)
          return response;
        if (gameParams.startingPlayer === GameParams.PlayerType.machinePlayer)
          return handler.handleMachinePlayInternal();
      }).catch(reason => {
        killGame(reason);
        emitChange(ActionStages.CHANGE_FAILURE);
      });
    },

    handleStartInternal: function(gameParams) {
      console.log("handle start internal");
      let valueFactory = PointValue.mkValueFactory(gameParams.dimension);
      let pointValues = valueFactory.mkValueGrid();
      let promise = _gameService.start([], [], [], pointValues);
      let processedPromise = promise.then(response => {
        if (response.ok) {
          _game = response.json;
          _status = OK;
          _auxGameData = emptyAuxGameData();
        }
        else {
          blankOutGame(gameParams, errorText(response));
        }
        emitChange(systemResponseType(response));
        return response;
      });
      return processedPromise;
    },

    handleMove: function(move) {
      if (noGame()) { logNoGame(); return; }
      _game = _game.applyUserMove(move);
      _status = OK;
      emitChange(ActionStages.CHANGE_SUCCESS);
    },

    handleRevertMove: function(piece) {
      if (noGame()) { logNoGame(); return; }
      _game = _game.revertMove(piece);
      _status = OK;
      emitChange(ActionStages.CHANGE_SUCCESS);
    },

    /*
     * Design Pattern - internal handlers.
     *
     * Internal handlers return promises that preserve rejections,
     * e.g., by not handling them in a catch. This allows higher-level
     * handlers to catch all rejections from lower levels in
     * one place. Also, higher level handlers assume that a resolved
     * promise received from a lower level handler will always
     * have an expected http response, with ok, status, etc. fields.
     */

    /**
     * See comments about internal handlers. Must preserve
     * rejections.
     */
    handleCommitPlayInternal: function() {
      if (noGame()) { logNoGame(); return; }
      let committedPlayPieces = undefined;
      try {
        committedPlayPieces = _game.getCompletedPlayPieces();
      } catch (ex) {
        let {name, message} = ex;
        _status = `${name}: ${message}`;
        let response = {
          json: "",
          ok: false,
          status: 422,
          statusText: _status
        };
        emitChange(systemResponseType(response));
        return Promise.resolve(response);
      }

      let promise = _gameService.commitUserPlay(_game.gameId, committedPlayPieces);
      let processedPromise = promise.then(response => {
        if (response.ok) {
          let {gameMiniState, replacementPieces, deadPoints} = response.json;
          let $game = _game.commitUserMoves(gameMiniState.lastPlayScore, replacementPieces);
          _game = $game.setDeadPoints(deadPoints);
          _status = OK;
          _auxGameData.pushWordPlayed(playPiecesWord(committedPlayPieces), "You"); // TODO. Use player name.
          emitChange(systemResponseType(response));
          return convertResponse(response, gameMiniState);
        }
        if (isUserError(response)) {
          _status = "error: " + errorText(response);
        }
        else {
          killGame(errorText(response));
        }
        emitChange(systemResponseType(response));
        return response;
      });
      return processedPromise;
    },

    /**
     * See comments about internal handlers. Must preserve
     * rejections.
     */
    handleMachinePlayInternal: function() {
      console.log("machine play internal");
      if (noGame()) { logNoGame(); return; }

      let promise = _gameService.getMachinePlay(_game.gameId);
      let processedPromise = promise.then(response => {
        if (response.ok) {
          let {gameMiniState, playedPieces, deadPoints} = response.json;
          let movedGridPieces = PlayPiece.movedGridPieces(playedPieces);
          let $game = _game.commitMachineMoves(gameMiniState.lastPlayScore, movedGridPieces);
          _game = $game.setDeadPoints(deadPoints);
          _status = movedGridPieces.length > 0 ? OK : "bot took a pass";
          _auxGameData.pushWordPlayed(playPiecesWord(playedPieces), "Bot"); // TODO. Constant.
          emitChange(systemResponseType(response));
          return convertResponse(response, gameMiniState);
        }

        killGame(errorText(response));
        emitChange(systemResponseType(response));
        return response;
      });
      return processedPromise;
    },

    handleCommitPlayAndGetMachinePlay: function() {
      if (noGame()) { logNoGame(); return; }
      let handler = this;
      handler.handleCommitPlayInternal().then(response => {
        if (!response.ok)
          return response;
        let gameMiniState = response.json;
        if (gameMiniState.noMorePlays) {
          return handler.handleCloseInternal();
        }
        else {
          handler.handleMachinePlayInternal().then(response => {
            if (!response.ok)
              return response;
            let gameMiniState = response.json;
            if (gameMiniState.noMorePlays) {
              return handler.handleCloseInternal();
            }
            else {
              return response;
            }
          });
        }
      }).catch(reason => {
        killGame(reason);
        emitChange(ActionStages.CHANGE_FAILURE);
      });
    },

    handleSwapAndGetMachinePlay: function(piece) {
      if (noGame()) { logNoGame(); return; }
      let handler = this;
      handler.handleSwapInternal(piece).then(response => {
        if (!response.ok)
          return response;
        let gameMiniState = response.json;
        // console.log(`swap - mini state: ${stringify(gameMiniState)}`);
        if (gameMiniState.noMorePlays) {
          return handler.handleCloseInternal();
        }
        else {
          handler.handleMachinePlayInternal().then(response => {
            if (!response.ok)
              return response;
            let gameMiniState = response.json;
            if (gameMiniState.noMorePlays) {
              return handler.handleCloseInternal();
            }
            else {
              return response;
            }
          });
        }
      }).catch(reason => {
        killGame(reason);
        emitChange(ActionStages.CHANGE_FAILURE);
      });
    },

    handleRevertPlay: function() {
      if (noGame()) { logNoGame(); return; }

      _game = _game.revertPlay();
      _status = OK;
      emitChange(ActionStages.CHANGE_SUCCESS);
    },

    gameSummaryStatus: function(stopInfo) {
      let {successivePasses} = stopInfo;
      let status = "game over - ";
      status += `${successivePasses} successive passes - maxed out`;
      return status;
    },

    handleCloseInternal: function () {
      if (noGame()) { logNoGame(); return; }
      let promise = _gameService.closeGame(_game.gameId);
      let processedResponse = promise.then(response => {
        if (response.ok) {
          let {stopInfo} = response.json;
          _game = _game.end();
          _status = this.gameSummaryStatus(stopInfo);
        }
        else {
          killGame(errorText(response));
        }
        emitChange(systemResponseType(response));
        return response;
      });
      return processedResponse;
    },

    handleSwapInternal: function (pc) {
      if (noGame()) { logNoGame(); return; }
      let promise = _gameService.swap(_game.gameId, pc);
      let processedPromise = promise.then(response => {
        if (response.ok) {
          let {gameMiniState, piece} = response.json;
          _game = _game.replaceTrayPiece(pc.id, piece);
          _status = OK;
          _auxGameData.pushWordPlayed("", "You");
          emitChange(systemResponseType(response));
          return convertResponse(response, gameMiniState);
        }
        killGame(errorText(response));
        emitChange(systemResponseType(response));
        return(response);
      }).catch(reason => {
        killGame(reason);
        emitChange(ActionStages.CHANGE_FAILURE);
      });
      return processedPromise;
    }
   };

  let dispatchHandler = function(action) {
    // if (_game !== undefined)
    //   _game.logGameState();

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
        console.log(`game event handler: unknown action type: ${action.type}`);
        return '';
    }
  };



  return {
    dispatchHandler: dispatchHandler,
    registerChangeObserver: registerChangeObserver,
    unregisterChangeObserver: unregisterChangeObserver
  }
};
