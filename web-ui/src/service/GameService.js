/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module GameService
 */

import {apiSelector} from '../api/ApiUtil';
import {GameConverter, PieceConverter, PlayConverter, GameParamsConverter} from './../api/Converters';
import Play from "../domain/Play";
// TODO. Should rejections be caught here and converted to just !ok??

/**
 * Abstraction layer above the api to hide the api implementation,
 * and to convert from application data structures to api data structures.
 */
class GameService {
  constructor(gameParams) {
    this.gameParams = gameParams;
    console.log(`game service constructor gameParams: ${JSON.stringify(this.gameParams)}`);
    this.paramsDto = GameParamsConverter.toJson(gameParams);
    console.log(`game service constructor paramsDto: ${JSON.stringify(this.paramsDto)}`);
    this.api = apiSelector(gameParams);
  }

  // TODO. The initialization arguments should be converted to dtos.
  start(initGridPieces, initUserTray, initMachineTray) {
    let promise = this.api.startGame(this.paramsDto, initGridPieces, initUserTray, initMachineTray);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let gameDto = dtoResponse.json;
      let game = GameConverter.fromJson(gameDto, this.gameParams);

      let response = this.convertResponse(dtoResponse, game);
      return response;
    });
  }

  end(gameId) {
    let promise = this.api.endPlay(gameId);
    return promise;
  }

  commitUserPlay(gameId, playPieces) {
    // TODO. Eliminate Play. Not really needed. playPieces is sufficient.
    let play = new Play(playPieces);
    let jsonPlayPieces = PlayConverter.toJson(play);
    let promise = this.api.commitPlay(gameId, jsonPlayPieces);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let refillPiecesDto = dtoResponse.json;
      let refillPieces = refillPiecesDto.map(PieceConverter.fromJson);
      let response = this.convertResponse(dtoResponse, refillPieces);
      return response;
    });
  }

  getMachinePlay(gameId) {
    let promise = this.api.getMachinePlay(gameId);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let playPiecesDto = dtoResponse.json;
      let play = PlayConverter.fromJson(playPiecesDto);
      let response = this.convertResponse(dtoResponse, play);
      return response;
    });
  }
  
  swap(gameId, piece) {
    let jsonPiece = PieceConverter.toJson(piece);
    let promise = this.api.swap(gameId, jsonPiece);
    return promise.then(dtoResponse => {
      if (!dtoResponse.ok) {
        return dtoResponse; // TODO. Convert dto message to application message;.
      }
      let jsonNewPiece = dtoResponse.json;
      let newPiece = PieceConverter.fromJson(jsonNewPiece);
      // console.log(`new piece: ${JSON.stringify(newPiece)}`);
      let response = this.convertResponse(dtoResponse, newPiece);
      return response;
    });
  }

  convertResponse(response, data) {
    let newResponse = Object.create(response);
    newResponse.json = data;
    return newResponse;
  }

}

export default GameService;