/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/**
 * @module MockGameImpl.
 */

import * as Piece from '../domain/Piece';

const pieceMoves = true;

// TODO. Take account of initialGrid and initial machine pieces.

class MockApiImpl {
  constructor(gameId, gameParams, initPieces, pointValues) {
    // TODO. Reflect initial conditions on game. Check server-side code for logic.
    this.gameParams = gameParams;
    this.nextPieceId = 0;
    this.dimension = gameParams.dimension;

    // this.machineTray = this.mkMachineTray();
    // this.machinePieces = this.getPieces(gameParams.trayCapacity);
    this.moves = [];
    // this.numPiecesInPlay = this.machineTray.pieces.length; // TODO. Use method.
    this.gameId = gameId;
    this.center = Math.floor(gameParams.dimension / 2);;

    let {boardPiecePoints, userPieces, machinePieces} = initPieces;

    // TODO. Streamline tray initialization.
    const additionalTrayPieces = this.getPieces(gameParams.trayCapacity - userPieces.length);
    const trayPieces = userPieces.concat(additionalTrayPieces);
    const additionalMachinePieces = this.getPieces(gameParams.trayCapacity - machinePieces.length);;
    this.machinePieces = machinePieces.concat(additionalMachinePieces);

    this.gameDto = {
      gameId: gameId,
      dimension: gameParams.dimension,
      trayCapacity: gameParams.trayCapacity,
      boardPiecePoints: [], // Start with an empty board. TODO. Use the init piece points.
      trayPieces: trayPieces
    };
  }

  // Begin Api.

  swap(piece) {
    let gameMiniState = {
      lastPlayScore: 0,
      scores: [0, 0],
      noMorePlays: false
    };
    return {
      gameMiniState: gameMiniState,
      piece: this.getPiece()};
  }

  mkMiniPlayState() {
    return {
      lastPlayScore: 10,
      scores: [10, 10],
      noMorePlays: false
    };
  }

  commitPlay(playPieces) {
    let it = this;
    let movedPlayPieces = playPieces.filter(p => p.moved);
    this.reflectMovesOnGame(movedPlayPieces);
    let usedUp = movedPlayPieces.length;
    movedPlayPieces.forEach(p =>
      it.removePieceById(it.gameDto.trayPieces, p.piece));
    let refills = this.getPieces(usedUp);
    refills.forEach(p =>
      it.gameDto.trayPieces.push(p));

    // console.log(`committed game: ${JSON.stringify(this.gameDto)}`);
    return {
      gameMiniState: this.mkMiniPlayState(),
      replacementPieces: refills,
      deadPoints: []
    };
  }

  isGameEmpty() {
    return this.gameDto.boardPiecePoints.length === 0;
  }

  /**
   * For now find the first position that has two empty positions below
   * and move the first two pieces from the tray to it.
   *
   * TODO. Add horizontal check as well.
   */
  getMachinePlay() {
    let it = this;
    let start = {row: this.center, col: this.center}
    let startPiece = this.getPiece();
    let startMoved = pieceMoves;

    if (!this.isGameEmpty()) {
      start = this.filledPositions().find(pos => it.twoBelowEmpty(pos, this.dimension));
      if (start === undefined) return [];
      startPiece = this.getBoardPiece(start);
      startMoved = !pieceMoves;
    }

    let startPlayPiece = this.mkPlayPiece(startPiece, start, startMoved);

    // Create moves from machine tray to 2 slots below the anchor.
    if (this.machinePieces.length < 2) return [];
    const [piece0, piece1] = this.machinePieces;
    // let piece0 = this.machinePieces[0];
    // let piece1 = this.machinePieces[1];
    const below = {row: start.row + 1, col: start.col};
    const belowBelow = {row: start.row + 2, col: start.col};
    const belowPlayPiece = this.mkPlayPiece(piece0, below, pieceMoves);
    const belowBelowPlayPiece = this.mkPlayPiece(piece1, belowBelow, pieceMoves);

    // Update and restock the machine tray.
    this.removePieceById(this.machinePieces, piece0);
    this.removePieceById(this.machinePieces, piece1);
    const refills = this.getPieces(2);
    refills.forEach(p => it.machinePieces.push(p));

    // Reflect the moves onto the board.
    const playPieces = [startPlayPiece, belowPlayPiece, belowBelowPlayPiece];
    const movedPlayPieces = playPieces.filter(p => p.moved);
    this.reflectMovesOnGame(movedPlayPieces);

    // Return entire sequence of play pieces to be returned, moved or not.
    return {
      gameMiniState: this.mkMiniPlayState(),
      playedPieces: playPieces,
      deadPoints: []
    };
  }

  // Future API member.
  selectFirstPlayer() {
    let player = Math.random() < 0.5 ? 'player' : 'machine'; // TODO. Common constants.
    return {
      player: player
    };
  }

  // End Api.
  
  // Begin auxiliary functions. Use in unit tests but not part of the api.
  
  filledPositions() {
    // console.log(`${JSON.stringify(this.gameDto.boardPiecePoints)}`);
    return this.gameDto.boardPiecePoints.map(piecePoint => piecePoint.point);
  }

  posFilled(pos) {
    return this.filledPositions().some (p => p.row === pos.row && p.col === pos.col);
  }

  posEmpty(pos) {
    return !this.posFilled(pos);
  }

  getPieces(numPieces) {
    let pieces = new Array;
    for (let i = 0; i < numPieces; i++)
      pieces.push(this.getPiece());
    return pieces;
  }

  getPiece() {
    this.nextPieceId += 1;
    const piece = {
      value: Piece.randomLetter(),
      id: String(this.nextPieceId)
    }
    this.numPiecesInPlay += 1;
    return piece;
  }
  
  // End auxiliary functions.

  // TODO. Private functions. Move these out of the class.

  getBoardPiece(point) {
    const piecePoint = this.gameDto.boardPiecePoints.find(piecePoint => {
      let pt = piecePoint.point;
      return point.row === pt.row && point.col === pt.col;
    });
    return (piecePoint !== undefined) ? piecePoint.piece : undefined;
  }

  removePieceById(pieces, piece) {
    const index = pieces.findIndex (function(p) {
      return (p.id === piece.id);
    });
    pieces.splice(index, 1);
  }

  mkPlayPiece(piece, point, moved) {
    return {
      point,
      piece,
      moved
    };
  }

  reflectMovesOnGame(movedPlayPieces) {
    let it = this;
    movedPlayPieces.forEach(playPiece =>
      this.gameDto.boardPiecePoints.push({piece: playPiece.piece, point: playPiece.point})
    );
  }

  twoBelowEmpty(pos, dimension) {
    // console.log(`pos: ${JSON.stringify(pos)}, dimension: ${JSON.stringify(dimension)}`);
    if (pos.row + 2 >= dimension)
      return false;
    return (this.posEmpty({row: pos.row + 1, col: pos.col}) && this.posEmpty({row: pos.row + 2, col: pos.col}));
  }
}

export default MockApiImpl;