/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkGame} from "../domain/Game";
import {mkBoard, mkEmptyBoard} from "../domain/Board";
import {mkTray} from "../domain/Tray";
import Play from "../domain/Play";
import {mkPiece} from "../domain/Piece";
import {mkPoint} from "../domain/Point";
import {mkGridPiece} from "../domain/GridPiece";
import {mkCommittedPlayPiece, mkPlayPiece} from "../domain/PlayPiece";
import {mkMultiplierGrid} from "../domain/ScoreMultiplier";

// TODO. Conversion of class object to json - use JSON.stringify in simple cases.
// TODO. What about conversion from json to a class object?

export const StartGameRequestConverter = {
  toJson: function(gameParams, initGridPieces, initUserPieces, initMachinePieces) {
    return {
      gameParams,
      initGridPieces,
      initUserPieces,
      initMachinePieces
    }
  }
}

export const GameParamsConverter = {
  toJson: function(gameParams) {
    return {
      dimension: gameParams.dimension,
      trayCapacity: gameParams.trayCapacity,
      languageCode: "",
      playerName: gameParams.appParams.userName,
      pieceGeneratorType: gameParams.pieceGeneratorType
    }
  }
};

export const GameConverter = {
  /**
   * @param json Represents DTO.
   * @param gameParams TODO. Clean it up so we don't need gameParams and paramsDto. Ugly hack.
   */
  fromJson: function(json, gameParams) {
    let gameId = json.gameId;
    let gridPiecesJson = json.gridPieces;
    let trayPiecesJson = json.trayPieces;
    let trayPieces = trayPiecesJson.map(p => PieceConverter.fromJson(p));
    let tray = mkTray(gameParams.trayCapacity, trayPieces);
    let playPieces = gridPiecesJson.map(gp => {
      // let piece = PieceConverter.fromJson(gp.piece);
      let piece = PieceConverter.fromJson(gp.value);
      let p = gp.point;
      let point = mkPoint(p.row, p.col);
      return mkCommittedPlayPiece(piece, point);
    });
    let dimension = gameParams.dimension;
    let board = mkEmptyBoard(dimension);
    // TODO. May gain some performance by providing board.setPlayPieces.
    // TODO. Or mkBoardFromPlayPieces, avoiding multiple clones.
    playPieces.forEach(playPiece => {
      board = board.setPlayPiece(playPiece);
    });
    let scoreMultipliers = mkMultiplierGrid(dimension);
    let game = mkGame(gameParams, gameId, board, tray, scoreMultipliers, [0, 0]);
    return game;
  }
};

export const PieceConverter = {
  fromJson: function(json) {
    return mkPiece(json.value, json.id);
  },

  toJson: function(piece) {
    return {
      value: piece.value,
      id: piece.id
    }
  }
};

export const PlayPieceConverter = {
  toJson: function(playPiece) {
    let point = playPiece.point;
    // console.log(`to - point: ${stringify(point)}`);
    return {
      piece: PieceConverter.toJson(playPiece.piece),
      point: {row: point.row, col: point.col},
      moved: playPiece.moved
    };
  },

  fromJson: function(json) {
    let piece = PieceConverter.fromJson(json.piece);
    let point = mkPoint(json.point.row, json.point.col);
    return mkPlayPiece(piece, point, json.moved);
  }
};

// export const PlayConverter = {
//   toJson: function(play) {
//     let playPieces = play.playPieces.map(playPiece => {
//       let moved = playPiece.moved;
//       let point = playPiece.point;
//       let piece = playPiece.piece;
//       return {
//         piece: piece,
//         point: point,
//         moved: moved
//       };
//     });
//     return playPieces;
//   },
//
//   fromJson: function(json) {
//     let playPiecesDto = json;
//     let playPieces = playPiecesDto.map(dto => PlayPieceConverter.fromJson(dto));
//     return new Play(playPieces);
//   }
// };

export const GridPieceConverter = {
  toJson: function(gridPiece) {
    let point = gridPiece.point;
    let piece = gridPiece.piece;
    return {
      piece: PieceConverter.toJson(piece),
      point: {row: point.row, col: point.col} // TODO. Unnecessary!
    };
  },
  
  fromJson: function(json) {
    let piece = json.piece;
    let point = json.point;
    let pos = mkPoint(point.row, point.col);
    return new mkGridPiece(PieceConverter.fromJson(piece), pos);
  }
};
