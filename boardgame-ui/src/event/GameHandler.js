/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


// TODO. Change notes about handling promises to reflect new model of internal calls.

import {stringify} from "../util/Logger";
// import {convertResponse} from "../util/MiscUtil";
// import ActionTypes from './GameActionTypes';
import ActionStages from './GameActionStages';
import {mkEmptyGame} from '../domain/Game';
import GameParams from '../domain/GameParams';
import * as PlayPiece from '../domain/PlayPiece';
import {playPiecesWord} from '../domain/PlayPiece';
import {emptyAuxGameData} from '../domain/AuxGameData';
import * as PointValue from '../domain/PointValue';
import {mkInitPieces} from '../domain/InitPieces';
import {NewActionTypes, startCompletion, startFailure} from "./NewActionTypes";
import {mkGameState} from "./GameState";

/**
 * High level service interface for manipulating gama data including storage and retrieval
 * in the backend game server. Deals with returned responses from the backend, converting
 * them to new game states that reflect success or failure, and dispatching notifications
 * about changes in the game state.
 *
 * Components call the methods of the this handler to implement user requests. Returns
 * from the handler are unspecified and are ignored by callers. The effect of each call
 * is dispatched s game state to interested parties who register observers with the handler.
 *
 * Basic design pattern.
 *
 * 1. Lower-level handlers in this module convert a response obtained
 * from the game service to a result data structure and return a promise of that data.
 * The data structure will include data about the game as well as indications of success
 * or failure.
 *
 * 2. Lower-level handlers do not catch rejections - so rejections bubble up.
 * This allows higher-level handlers to catch all rejections from lower levels in one place.
 *
 * 3. High-level API calls are responsible to dispatch the game state (using emitChange) in all
 * cases.
 *
 * Terminology:
 *
 *    auxGameData - includes the list of words played so far in the game + the corresponding player
 *    status - http status
 *    opStatus - message about the result of an operation - for presentation to user
 *    gameMiniState - minimal backed information about the state of the game,
 *       includes, e.g., noMorePlays (the backend ended the game, e.g. the game has timed out)
 *
 * @param gameService - The lower level game service making http requests to the backend.
 * @returns {{handler registerChangeObserver, unregisterChangeObserver}}
 *
 *  handler - the top level service object to be called by components
 *  subscribe - subscribe to get notifications of state changes made by the handler
 *                subscriber callbacks are notified via a GameState object
 *  unsubscribe - remove a subscription
 */
export const mkGameHandler = function(gameService) {
  let _gameService = gameService;
  let _changeObservers = [];

  const OK = "OK";
  const USER_START_STATUS = "your play ...";
  const MACHINE_START_STATUS = "bot's play - thinking ...";

  const unrecoverableErrorMessage = "we are sorry - the system encountered an unrecoverable error - and had to stop the game - ";

  /**
   * Register an observer of state changes made by the handler.
   * @param observer - A function that consumes a single parameter - the game state.
   */
  const subscribe = function(observer) {
    // Yes - function references can be compared as references.
    if (!_changeObservers.find((obs) => (obs === observer)))
      _changeObservers.push(observer);
  };

  /**
   * Unregister an observer of state changes made by the handler.
   */
  const unsubscribe = function(observer) {
    let index = _changeObservers.findIndex((obs) => (obs === observer));
    if (index === -1)
      return;
    _changeObservers.splice(index, 1);
  };

  /**
   * Notify subscribers of change of state.
   */
  const emitChange = function(gameState) {
    _changeObservers.forEach(
      function (observer) {
        observer(gameState);
      }
    );
  };

  const noAuxData = emptyAuxGameData();

  const isUserError = (response) => response.status === 422;

  const revertParamsToDefault = function(gameParams) {
    let isProd = gameParams.appParams.envType === 'prod'; // TODO. Constant for prod.
    let params = isProd ? GameParams.defaultClientParams() : GameParams.defaultParams();
    return params;
  };

  const blankOutGame = function(gameParams, message, actionType) {
    let stableParams = revertParamsToDefault(gameParams);
    return mkGameState(
      mkEmptyGame(stableParams),
      emptyAuxGameData(),
      unrecoverableErrorMessage + message,
      actionType
    )
  };

  /**
   * For now we use the default error message provided by the server.
   * Future clients may wish to further customize messages using specific
   * fields of each type of error. But note that as of May 2018 the error
   * API has not been standardized.
   */
  const errorText = (response) => {
    let json = response.json;
    let message = json.message;
    if (message === undefined)
      message = stringify(json);
    return message;
  };

  const closeDataToGameState = function(auxGameData, closeData, mkResultActionType) {
    return mkGameState(closeData.game, auxGameData, closeData.opStatus, mkResultActionType(closeData.ok));
  };

  const noGame = (game) => game === undefined || game.terminated();

  const logNoGame = () => console.log('warning: game event handler called with no game in effect');

  const machineStarts = (gameParams) => gameParams.startingPlayer === GameParams.PlayerType.machinePlayer;

  const playerStarts = (gameParams) => !machineStarts(gameParams);

  const startSuccessOpStatus = function(gameParams) {
    return machineStarts(gameParams) ? MACHINE_START_STATUS : USER_START_STATUS;
  };

  const mkStartErrorState = function(gameParams, response) {
    return mkGameState(mkEmptyGame(gameParams), emptyAuxGameData(), errorText(response), NewActionTypes.START_FAILURE);
  };

  const commitDataToGameState = function(data, actionType) {
    mkGameState(data.game, data.auxGameData, data.opStatus, actionType);
  };

  const machinePlayDataToGameState = function(data, actionType) {
    return mkGameState(data.game, data.auxGameData, data.opStatus, actionType);
  };

  let handler = {

    /**
     * Starts a game based on the input game parameters. Among other things, the starting
     * player is specified in the input parameters. If the starting player is the machine,
     * calls the backed to get the first play and reflect on the board.
     */
    handleStart: function(gameParams) {
      console.log(`handle start - ${stringify(gameParams)}`);
      // No need for triggering START_INIT for now. Keep it simple.
      let handler = this;
      handler.handleStartInternal(gameParams).then(gameState => {
        if (playerStarts(gameParams) || startFailure(gameState.actionType))
          emitChange(gameState);
        else
          handler.handleMachinePlayInternal(gameState.game, gameState.auxGameData)
            .then(playData => {
              let gameState = machinePlayDataToGameState(playData, startCompletion(playData.ok));
              emitChange(gameState)
            });
        })
        .catch(reason => {
          const failureState = blankOutGame(gameParams, stringify(reason), NewActionTypes.START_FAILURE);
          emitChange(failureState);
        });
    },

    /**
     * Starts a game based on the input parameters without doing any plays and
     * returns the game state for the started game.
     */
    handleStartInternal: function(gameParams) {
      console.log("handle start internal");
      let valueFactory = PointValue.mkValueFactory(gameParams.dimension);
      let pointValues = valueFactory.mkValueGrid();
      let initPieces = mkInitPieces([], [], []);
      let promise = _gameService.start(initPieces, pointValues);
      return promise.then(response => {
        if (!response.ok)
          return mkStartErrorState(gameParams, response);
        else
          return mkGameState(response.json, noAuxData, startSuccessOpStatus(gameParams), NewActionTypes.START_SUCCESS);
      });
    },

    /**
     * Reflect a single move of a piece from the tray to the board.
     *
     * @param move - A move object that include the piece and the destination point on the board:
     *               { piece, point }.
     */
    handleMove: function(game, auxGameData, move) {
      if (noGame(game)) { logNoGame(); return; }
      // TODO. Could this call fail? If so need to return failure state.
      const updatedGame = game.applyUserMove(move);
      const gameState = mkGameState(updatedGame, auxGameData, OK, NewActionTypes.MOVE_SUCCESS);
      emitChange(gameState);
    },

    /**
     * Reverse an earlier move by moving its piece from the board to the tray;
     * reflect the result on the board.
     */
    handleRevertMove: function(game, auxGameData, piece) {
      if (noGame(game)) { logNoGame(); return; }
      const updatedGame = game.revertMove(piece);
      const gameState = mkGameState(updatedGame, auxGameData, OK, NewActionTypes.REVERT_MOVE_SUCCESS);
      emitChange(gameState);
    },

    /**
     * Commit a user play and return the resulting committed game data:
     * {game, auxGameData, ok, status, opStatus}
     */
    handleCommitPlayInternal: function(game, auxGameData) {
      if (noGame(game)) { logNoGame(); return; }
      let committedPlayPieces = undefined;
      try {
        committedPlayPieces = game.getCompletedPlayPieces();
      } catch (ex) {
        let {name, message} = ex;
        let opStatus = `${name}: ${message}`;
        let commitData = {game, auxGameData, ok: false, status: 422, opStatus};
        return Promise.resolve(commitData);
      }

      let promise = _gameService.commitUserPlay(game.gameId, committedPlayPieces);
      let processedPromise = promise.then(
        response => {
          const defaultResult = {game, auxGameData, ok: true, status: response.status, opStatus: OK};
          const errOpStatus = "error: " + errorText(response);

          const happyCommitData = function() {
            let {gameMiniState, replacementPieces, deadPoints} = response.json;
            let updatedGame = game.commitUserMoves(gameMiniState.lastPlayScore, replacementPieces, deadPoints);
            let word = playPiecesWord(committedPlayPieces);
            let updatedAuxGameData = auxGameData.pushWordPlayed(word, "You"); // TODO. Use player name.
            return {...defaultResult, game: updatedGame, auxGameData: updatedAuxGameData, gameMiniState};
          };

          const unhappyCommitData = function(status) {
            return {...defaultResult, ok: false, status, opStatus: errOpStatus};
          };

          if (response.ok)
            return happyCommitData(response);
          else if (isUserError(response))
            return unhappyCommitData(422);
          else
            return unhappyCommitData(500);
      });
      return processedPromise;
    },

    /**
     * Get a machine play from the backend and return data about it:
     * {game, auxGameData, opStatus, ok, gameMiniState}
     */
    handleMachinePlayInternal: function(game, auxGameData) {
      console.log("machine play internal");
      if (noGame()) { logNoGame(); return; }

      let promise = _gameService.getMachinePlay(game.gameId);
      return promise.then(response => {
        const defaultResult = {game, auxGameData, ok: true};

        const happyMachineData = function() {
          let {gameMiniState, playedPieces, deadPoints} = response.json;
          let movedPiecePoints = PlayPiece.movedPiecePoints(playedPieces);
          let updatedGame = game.commitMachineMoves(gameMiniState.lastPlayScore, movedPiecePoints, deadPoints);
          let updatedAuxGameData = auxGameData.pushWordPlayed(playPiecesWord(playedPieces), "Bot");
          let opStatus = movedPiecePoints.length > 0 ? OK : "bot took a pass";
          return {...defaultResult, game: updatedGame, auxGameData: updatedAuxGameData, opStatus, gameMiniState};
        };

        const unhappyMachineData = function() {
          const emptyGame = mkEmptyGame(game.gameParams);
          const opStatus = errorText(response);
          return {...defaultResult, game: emptyGame, auxGameData: emptyAuxGameData(), opStatus, ok: false}
        };

        if (response.ok)
          return happyMachineData();
        else
          return unhappyMachineData();
      });
    },

    handleCommitPlayAndGetMachinePlay: function(game, auxGameData) {
      if (noGame(game)) { logNoGame(); return; }
      let handler = this;
      handler.handleCommitPlayInternal().then(commitData => {

        if (!commitData.ok) {
          let gameState = commitDataToGameState(commitData.game, NewActionTypes.COMMIT_PLAY_FAILURE);
          emitChange(gameState);
        }

        const resultActionType = function(ok) {
          return ok ? NewActionTypes.COMMIT_PLAY_SUCCESS : NewActionTypes.COMMIT_PLAY_FAILURE;
        };

        const {gameMiniState} = commitData;
        const {noMorePlays} = gameMiniState;

        if (noMorePlays)
          // TODO. Check that auxGameData is up-to-date.
          handler.gameCloserHelper(game, auxGameData, resultActionType).then(
            gameState => emitChange(gameState)
          );
        else
          return handler.handleMachinePlayInternal(game, auxGameData).then(machinePlayData => {
            handler.completeMachinePlay(machinePlayData, resultActionType).then(
              gameState => emitChange(gameState)
            )
          });
      }).catch(reason => {
        const failureState = blankOutGame(game.gameParams, stringify(reason), NewActionTypes.COMMIT_FAILURE);
        emitChange(failureState);
      });
    },

    completeMachinePlay: function(machinePlayData, resultActionType) {
      let actionType = resultActionType(machinePlayData.ok);
      let gameState = machinePlayDataToGameState(machinePlayData, actionType);
      let defaultPromise = Promise.resolve(gameState);
      if (!machinePlayData.ok)
        return defaultPromise;
      else {
        let {gameMiniState} = machinePlayData;
        let shouldClose = gameMiniState.noMorePlays;
        if (!shouldClose)
          return defaultPromise;
        else
          handler.gameCloserHelper(gameState.game, gameState.auxGameData, resultActionType).then(
            gameState => {
              return gameState
            }
          );
      }
    },

    handleSwapAndGetMachinePlay: function(game, auxGameData, piece) {
      if (noGame(game)) { logNoGame(); return; }
      let handler = this;

      const resultActionType = function(ok) {
        return ok ? NewActionTypes.SWAP_SUCCESS : NewActionTypes.SWAP_FAILURE;
      };

      handler.handleSwapInternal(game, auxGameData, piece).then(swapData => {

        const swapDataToGameState = function() {
          return mkGameState(swapData.game, swapData.auxGameData, swapData.opStatus, resultActionType(swapData.ok));
        };

        const gameState = swapDataToGameState();

        if (!swapData.ok)
          emitChange(gameState);
        else {
          let {gameMiniState} = swapData;
          if (gameMiniState.noMorePlays)
            handler.gameCloserHelper(gameState.game, gameState.auxGameData, resultActionType).then(
              gameState => emitChange(gameState)
            );
          else {
            return handler.handleMachinePlayInternal(gameState.game, gameState.auxGameData).then(machinePlayData => {
              handler.completeMachinePlay(machinePlayData, resultActionType).then(
                gameState => emitChange(gameState)
              )
            });
          }
        }
      }).catch(reason => {
        const failureState = blankOutGame(game.gameParams, stringify(reason), NewActionTypes.SWAP_FAILURE);
        emitChange(failureState);
      });
    },

    handleRevertPlay: function(game, auxGameData) {
      if (noGame()) { logNoGame(); return; }
      const updatedGame = game.revertPlay();
      const gameState = mkGameState(updatedGame, auxGameData, OK, NewActionTypes.REVERT_PLAY_SUCCESS);
      emitChange(gameState);
    },

    gameSummaryStatus: function(stopInfo) {
      let {successivePasses, filledBoard} = stopInfo;
      let status = "game over - ";
      status += filledBoard ? `full board` : `${successivePasses} successive passes - maxed out`;
      return status;
    },

    handleCloseInternal: function (game) {
      if (noGame(game)) { logNoGame(); return; }
      let promise = _gameService.gameCloserHelper(game.gameId);
      let processedResponse = promise.then(response => {

        const happyCloseData = function() {
          let {stopInfo} = response.json;
          const updatedGame = game.end();
          const opStatus = this.gameSummaryStatus(stopInfo);
          return {game: updatedGame, opStatus, ok: true, stopInfo};
        };

        const unhappyCloseData = function() {
          const opStatus = errorText(response);
          return {game, opStatus, ok: false}
        };

        if (response.ok)
          return happyCloseData();
        else
          return unhappyCloseData();
      });
      return processedResponse;
    },

    gameCloserHelper: function(game, auxGameData, resultActionType) {
      return handler.handleCloseInternal(game).then(
        closeData => {
          return closeDataToGameState(closeData, auxGameData, resultActionType);
          // emitChange(gameState);
        }
      );
    },

    handleSwapInternal: function (game, auxGameData, pc) {
      if (noGame()) { logNoGame(); return; }
      let promise = _gameService.swap(game.gameId, pc);
      let processedPromise = promise.then(response => {
        const defaultResult = {game, auxGameData, opStatus: OK, ok: true};

        const happySwapData = function() {
          let {gameMiniState, piece} = response.json;
          const updatedGame = game.replaceTrayPiece(pc.id, piece);
          const updatedAuxGameData = auxGameData.pushWordPlayed("", "You");
          return {...defaultResult, game: updatedGame, auxGameData: updatedAuxGameData, gameMiniState};
        };

        const unhappySwapData = function() {
          const opStatus = errorText(response);
          return {...defaultResult, opStatus, ok: false};
        };

        if (response.ok)
          return happySwapData();
        else
          return unhappySwapData();
      });
      return processedPromise;
    }

   };

  return {
    handler,
    subscribe,
    unsubscribe
  }
};
