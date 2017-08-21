/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkEmptyBoard} from '../domain/Board';
import {mkPiece} from '../domain/Piece';
import {mkPoint} from '../domain/Point';
import {mkCommittedPlayPiece, mkMovePlayPiece} from '../domain/PlayPiece';
import {range} from '../util/MiscUtil';

test('move forming a maximum gap is allowed', () => {
  let board = mkEmptyBoard(5);
  let origCol = 1;
  let point = mkPoint(1, origCol);
  let barePlayPiece = board.getPlayPiece(point);
  let piece = mkPiece('A', 'idA');
  let playPiece = barePlayPiece.putPiece(piece);
  let $board = board.setPlayPiece(playPiece);
  let movingPiece = mkPiece('B', 'idB');
  let destCol = 4;
  let dest = mkPoint(1, destCol);
  let neededTrayPieces = destCol - origCol;
  let legal = $board.legalMove(movingPiece, dest, neededTrayPieces);
  expect(legal).toBe(true);
});

test('move going beyond the maximum gap is disallowed', () => {
  let board = mkEmptyBoard(5);
  let origCol = 1;
  let point = mkPoint(1, origCol);
  let barePlayPiece = board.getPlayPiece(point);
  let piece = mkPiece('A', 'idA');
  let playPiece = barePlayPiece.putPiece(piece);
  let $board = board.setPlayPiece(playPiece);
  let movingPiece = mkPiece('B', 'idB');
  let destCol = 4;
  let dest = mkPoint(1, destCol);
  let neededTrayPieces = destCol - origCol;
  let numTrayPieces = destCol - origCol - 1;
  let legal = $board.legalMove(movingPiece, dest, numTrayPieces);
  expect(legal).toBe(false);
});

test('moves leave gaps then fill gaps', () => {
  let dimension = 5;
  let board = mkEmptyBoard(dimension);
  let mid = Math.floor(dimension/2);
  let centerPoint = mkPoint(mid, mid);
  let centerPiece = mkPiece('E', 'id0');
  let centerPlayPiece = mkCommittedPlayPiece(centerPiece, centerPoint);
  let $board = board.setPlayPiece(centerPlayPiece);
  let numTrayPieces = dimension;
  let pieces = [mkPiece('A', '1'), mkPiece('B', '2'), mkPiece('C', '3'), mkPiece('D', '4'), mkPiece('E', '5')];
  let row2Points = range(dimension).map(col => mkPoint(mid, col));
  let movingPlayPieces = range(dimension).map(i => mkMovePlayPiece(pieces[i], row2Points[i]));
  let makeMove = function(i) {
    let legal = $board.legalMove(pieces[i], row2Points[i], numTrayPieces);
    expect(legal).toBe(true);
    $board = $board.setPlayPiece(movingPlayPieces[i]);
    numTrayPieces--;
  };
  makeMove(0);
  makeMove(4);
  // col 2 has the original piece 'E'.
  makeMove(1);
  makeMove(3);

  let num = $board.completedPlayPieces().length;
  expect(num).toBe(5);
});

test('move to empty line is disallowed', () => {
  let board = mkEmptyBoard(5);
  let origCol = 1;
  let origRow = 1;
  let point = mkPoint(origRow, origCol);
  let barePlayPiece = board.getPlayPiece(point);
  let piece = mkPiece('A', 'idA');
  let playPiece = barePlayPiece.putPiece(piece);
  let $board = board.setPlayPiece(playPiece);
  let movingPiece = mkPiece('B', 'idB');
  let destRow = origRow + 1;
  let destCol = origCol + 1;
  let dest = mkPoint(destRow, destCol);
  let numTrayPieces = 5;
  let legal = $board.legalMove(movingPiece, dest, numTrayPieces);
  expect(legal).toBe(false);
});

test('get completed horizontal play', () => {
  let dimension = 9;
  let row = 4;
  let col = 4;
  let numTrayPieces = 2;

  let board = mkEmptyBoard(dimension);
  let pieceA = mkPiece('A', '1');
  let pointA = mkPoint(row, col);
  let $board = board.setPlayPiece(mkCommittedPlayPiece(pieceA, pointA));
  
  let pieceB = mkPiece('B', '2');
  let pointB = mkPoint(row, col - 2);
  $board = $board.setPlayPiece(mkCommittedPlayPiece(pieceB, pointB));

  let pieceC = mkPiece('C', '3');
  let pointC = mkPoint(row, col - 1);
  $board = $board.setPlayPiece(mkMovePlayPiece(pieceC, pointC));
  
  let pieceD = mkPiece('D', '4');
  let pointD = mkPoint(row, col + 1);
  $board = $board.setPlayPiece(mkMovePlayPiece(pieceD, pointD));
  
  let playPieces = $board.completedPlayPieces();
  expect(playPieces.length).toBe(4);
});

test('get completed vertical play', () => {
  let dimension = 9;
  let row = 4;
  let col = 4;
  let numTrayPieces = 2;

  let board = mkEmptyBoard(dimension);
  let pieceA = mkPiece('A', '1');
  let pointA = mkPoint(row, col);
  let $board = board.setPlayPiece(mkCommittedPlayPiece(pieceA, pointA));

  let pieceB = mkPiece('B', '2');
  let pointB = mkPoint(row - 2, col);
  $board = $board.setPlayPiece(mkCommittedPlayPiece(pieceB, pointB));

  let pieceC = mkPiece('C', '3');
  let pointC = mkPoint(row - 1, col);
  $board = $board.setPlayPiece(mkMovePlayPiece(pieceC, pointC));

  let pieceD = mkPiece('D', '4');
  let pointD = mkPoint(row + 1, col);
  $board = $board.setPlayPiece(mkMovePlayPiece(pieceD, pointD));

  let playPieces = $board.completedPlayPieces();
  expect(playPieces.length).toBe(4);
});


