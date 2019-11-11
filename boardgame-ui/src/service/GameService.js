/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameService
 */

import {apiSelector} from '../api/ApiUtil';
import {GameConverter, PieceConverter, GameParamsConverter} from './../api/Converters';
// import Play from "../domain/Play";
// import {stringify} from "../util/Logger";
// import * as PointValue from '../domain/PointValue';

import {convertResponse} from "../util/MiscUtil";
import {PlayPieceConverter} from "../api/Converters";
import {PointConverter} from "../api/Converters";
// TODO. Should rejections be caught here and converted to just !ok??

/**
 * Abstraction layer above the api to hide the api implementation,
 * and to convert from application data structures to api data structures.
 */
class GameService {
  constructor(gameParams) {
    this.gameParams = gameParams;
    // console.log(`game service constructor gameParams: ${JSON.stringify(this.gameParams)}`);
    this.paramsDto = GameParamsConverter.toJson(gameParams);
    // console.log(`game service constructor paramsDto: ${JSON.stringify(this.paramsDto)}`);
    this.api = apiSelector(gameParams);
  }

  handShake() {
    return this.api.handShake();
  }

  // TODO. The initialization arguments should be converted to dtos.
  start(initPieces, pointValues) {
    let promise = this.api.startGame(this.paramsDto, initPieces, pointValues.rows());
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message.
      }
      let gameDto = dtoResponse.json;
      // console.log(`game dto returned from start: ${JSON.stringify(gameDto)}`); // TODO. Remove me.
      let game = GameConverter.fromJson(gameDto, this.gameParams, pointValues);

      let response = convertResponse(dtoResponse, game);
      return response;
    });
  }

  closeGame(gameId) {
    let promise = this.api.gameCloserHelper(gameId);
    return promise;
  }

  commitUserPlay(gameId, playPieces) {
    // TODO. Eliminate Play. Not really needed. playPieces is sufficient.
    // let play = new Play(playPieces);
    // let jsonPlayPieces = PlayConverter.toJson(play);
    let jsonPlayPieces = playPieces.map(playPiece => PlayPieceConverter.toJson(playPiece));
    // console.log(`json play pieces: ${stringify(jsonPlayPieces)}`);
    let promise = this.api.commitPlay(gameId, jsonPlayPieces);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let {gameMiniState, replacementPieces, deadPoints} = dtoResponse.json;
      let replacementPiecesObjects = replacementPieces.map(PieceConverter.fromJson);
      let deadPointObjects = deadPoints.map(js => PointConverter.fromJson(js));
      let result = {
        gameMiniState: gameMiniState,
        replacementPieces: replacementPiecesObjects,
        deadPoints: deadPointObjects
      };

      let response = convertResponse(dtoResponse, result);
      return response;
    });
  }

  getMachinePlay(gameId) {
    let promise = this.api.getMachinePlay(gameId);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let {gameMiniState, playedPieces, deadPoints} = dtoResponse.json;
      // let play = PlayConverter.fromJson(playedPieces);
      let playPiecesObjects = playedPieces.map(playPiece => PlayPieceConverter.fromJson(playPiece));
      let deadPointObjects = deadPoints.map(js => PointConverter.fromJson(js));
      let result = {
        gameMiniState: gameMiniState,
        playedPieces: playPiecesObjects,
        deadPoints: deadPointObjects
      };
      let response = convertResponse(dtoResponse, result);
      return response;
    });
  }
  
  swap(gameId, pc) {
    let jsonPiece = PieceConverter.toJson(pc);
    let promise = this.api.swap(gameId, jsonPiece);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let {gameMiniState, piece} = dtoResponse.json;
      let newPiece = PieceConverter.fromJson(piece);
      // console.log(`new piece: ${JSON.stringify(newPiece)}`);
      let result = {
        gameMiniState: gameMiniState,
        piece: newPiece
      };
      let response = convertResponse(dtoResponse, result);
      return response;
    });
  }


}

export default GameService;