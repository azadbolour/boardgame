/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkEmptyBoard} from '../domain/Board';
import {mkPiece} from '../domain/Piece';
import {mkPoint} from '../domain/Point';
import {mkCommittedPlayPiece, mkMovePlayPiece, playPiecesWord} from '../domain/PlayPiece';

// test.only runs the given test only.

test('board set and get element', () => {
  let board = mkEmptyBoard(2);
  let point = mkPoint(0, 0);
  let barePlayPiece = board.getPlayPiece(point);
  expect(barePlayPiece.point.row).toBe(0);

  let piece = mkPiece('A', 'idA');
  let playPiece = barePlayPiece.putPiece(piece);
  expect(playPiece.piece.value).toBe('A');

  let $board = board.setPlayPiece(playPiece);
  let pp = $board.getPlayPiece(point);
  expect(pp.piece.value).toBe('A');

  let num = $board.numMoves();
  expect(num).toBe(0);

  let otherPoint = mkPoint(1, 0);
  let movedPlayPiece = barePlayPiece.setMovedIn(piece);

  $board = board.setPlayPiece(movedPlayPiece);
  num = $board.numMoves();
  expect(num).toBe(1);
});

test('completed 2-letter word', () => {
  let dimension = 5;
  let board = mkEmptyBoard(dimension);
  let mid = Math.floor(dimension/2);
  let centerPoint = mkPoint(mid, mid);
  let centerPiece = mkPiece('E', 'id0');
  let centerPlayPiece = mkCommittedPlayPiece(centerPiece, centerPoint);
  let $board = board.setPlayPiece(centerPlayPiece);
  let numTrayPieces = dimension;
  let pointAbove = mkPoint(mid - 1, mid);
  let pieceAbove = mkPiece('B', 'id1');
  let playPieceAbove = mkMovePlayPiece(pieceAbove, pointAbove);
  $board = $board.setPlayPiece(playPieceAbove);
  let wordPlayPieces = $board.completedPlayPieces();
  expect(wordPlayPieces.length).toBe(2);
});

test('completed 2-letter word in both directions', () => {
  let dimension = 5;
  let board = mkEmptyBoard(dimension);
  let mid = Math.floor(dimension/2);
  let centerPoint = mkPoint(mid, mid);
  let centerPiece = mkPiece('E', 'id0');
  let centerPlayPiece = mkCommittedPlayPiece(centerPiece, centerPoint);
  let $board = board.setPlayPiece(centerPlayPiece);
  let kittyCornerPoint = mkPoint(mid - 1, mid + 1);
  let kittyCornerPiece = mkPiece('E', 'kitty');
  let kittyCornerPlayPiece = mkCommittedPlayPiece(kittyCornerPiece, kittyCornerPoint);
  $board = $board.setPlayPiece(kittyCornerPlayPiece);
  let numTrayPieces = dimension;
  let pointAbove = mkPoint(mid - 1, mid);
  let pieceAbove = mkPiece('B', 'id1');
  let playPieceAbove = mkMovePlayPiece(pieceAbove, pointAbove);
  $board = $board.setPlayPiece(playPieceAbove);
  let wordPlayPieces = $board.completedPlayPieces();
  expect(wordPlayPieces.length).toBe(2);
});

test('single move leads to vertical completion and horizontal gap', () => {
  let dimension = 5;
  let board = mkEmptyBoard(dimension);
  let mid = Math.floor(dimension/2);
  let centerPoint = mkPoint(mid, mid);
  let centerPiece = mkPiece('E', 'id0');
  let centerPlayPiece = mkCommittedPlayPiece(centerPiece, centerPoint);
  let $board = board.setPlayPiece(centerPlayPiece);

  // The pattern. 'A is the move.

  //  B I T
  // 'A   E
  //  H E N

  // TEN vertically.
  let pointT = mkPoint(mid - 1, mid);
  let pieceT = mkPiece('T', 'id1');
  let playPieceT = mkCommittedPlayPiece(pieceT, pointT);
  $board = $board.setPlayPiece(playPieceT);
  let pointN = mkPoint(mid + 1, mid);
  let pieceN = mkPiece('N', 'id2');
  let playPieceN = mkCommittedPlayPiece(pieceN, pointN);
  $board = $board.setPlayPiece(playPieceN);

  // BIT horizontally.
  let pointB = mkPoint(mid - 1, mid - 2);
  let pieceB = mkPiece('B', 'id3');
  let playPieceB = mkCommittedPlayPiece(pieceB, pointB);
  $board = $board.setPlayPiece(playPieceB);
  let pointI = mkPoint(mid - 1, mid - 1);
  let pieceI = mkPiece('I', 'id4');
  let playPieceI = mkCommittedPlayPiece(pieceI, pointI);
  $board = $board.setPlayPiece(playPieceI);

  // HEN horizontally.
  let pointH = mkPoint(mid + 1, mid - 2);
  let pieceH = mkPiece('H', 'id5');
  let playPieceH = mkCommittedPlayPiece(pieceH, pointH);
  $board = $board.setPlayPiece(playPieceH);
  let pointE = mkPoint(mid + 1, mid - 1);
  let pieceE = mkPiece('E', 'id6');
  let playPieceE = mkCommittedPlayPiece(pieceE, pointE);
  $board = $board.setPlayPiece(playPieceE);

  // Now add the move that fills vertical gap but not horizontal gap.

  let pointA = mkPoint(mid, mid - 2);
  let pieceA = mkPiece('A', 'id7');
  let playPieceA = mkMovePlayPiece(pieceA, pointA);
  $board = $board.setPlayPiece(playPieceA);

  let wordPlayPieces = $board.completedPlayPieces();
  let word = playPiecesWord(wordPlayPieces);
  console.log(word[1]);
  expect(word).toBe('BAH');

  // TODO. Do the same but reverse X and Y axes.
});




