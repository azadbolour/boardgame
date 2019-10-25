/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkEmptyBoard} from '../domain/Board';
import {mkPiece} from '../domain/Piece';
import {mkPoint} from '../domain/Point';
import {mkCommittedPlayPiece, mkMovePlayPiece} from '../domain/PlayPiece';
import {range} from '../util/MiscUtil';

const initBoard = function(dimension) {
  let board = mkEmptyBoard(dimension);
  let mid = Math.floor(dimension/2);
  let centerPlayPiece = mkCommittedPlayPiece(mkPiece('O', 'id0'), mkPoint(mid, mid));
  board = board.setPlayPiece(centerPlayPiece);
  let prevPlayPiece = mkCommittedPlayPiece(mkPiece('S', 'id1'), mkPoint(mid, mid - 1));
  board = board.setPlayPiece(prevPlayPiece);
  return {
    mid,
    board
  };
};

const pcs = [
  mkPiece('A', 'ida'),
  mkPiece('B', 'idb'),
  mkPiece('C', 'idc'),
  mkPiece('D', 'idd'),
  mkPiece('E', 'ide'),
  mkPiece('F', 'idf')
];

test('multiple play lines', () => {
  let dimension = 5;
  let {mid, board} = initBoard(dimension);

  let playPiece1 = mkMovePlayPiece(pcs[0], mkPoint(mid - 1, mid - 1));
  let playPiece2 = mkMovePlayPiece(pcs[1], mkPoint(mid, mid + 1));
  board = board.setPlayPiece(playPiece1);
  board = board.setPlayPiece(playPiece2);

  expect(() => board.completedPlayPieces()).toThrow();
  try {
    board.completedPlayPieces();
  } catch (ex) {
    console.log(`${stringify(ex)}`);
  }

});

test('non-contiguous play', () => {
  let dimension = 5;
  let {mid, board} = initBoard(dimension);

  let playPiece1 = mkMovePlayPiece(pcs[0], mkPoint(mid - 1, mid));
  let playPiece2 = mkMovePlayPiece(pcs[1], mkPoint(mid + 2, mid));
  board = board.setPlayPiece(playPiece1);
  board = board.setPlayPiece(playPiece2);

  expect(() => board.completedPlayPieces()).toThrow();
  try {
    board.completedPlayPieces();
  } catch (ex) {
    console.log(`${stringify(ex)}`);
  }
});


test('make word by adding a single cross letter', () => {
  let dimension = 5;
  let board = mkEmptyBoard(dimension);
  let playPiece1 = mkCommittedPlayPiece(pcs[0], mkPoint(1, 0));
  let playPiece2 = mkCommittedPlayPiece(pcs[1], mkPoint(2, 0));
  let playPiece3 = mkCommittedPlayPiece(pcs[2], mkPoint(3, 0));
  board = board.setPlayPiece(playPiece1);
  board = board.setPlayPiece(playPiece2);
  board = board.setPlayPiece(playPiece3);

  let playPiece4 = mkMovePlayPiece(pcs[3], mkPoint(2, 1));
  board = board.setPlayPiece(playPiece4);
  let playPieces = board.completedPlayPieces();
  expect(playPieces.length).toBe(2);
});


test('parallel play straddles multiple adjacent words', () => {
  let dimension = 5;
  let {mid, board} = initBoard(dimension);

  // Add another word to the line. Not legal or connected but that is OK for testing.
  let playPiece1 = mkCommittedPlayPiece(pcs[0], mkPoint(mid, 4));
  board = board.setPlayPiece(playPiece1);

  // Make a play that neighbors the previous play and the initial centered play.
  let playPiece2 = mkMovePlayPiece(pcs[1], mkPoint(mid - 1, 2));
  let playPiece3 = mkMovePlayPiece(pcs[2], mkPoint(mid - 1, 3));
  let playPiece4 = mkMovePlayPiece(pcs[3], mkPoint(mid - 1, 4));
  board = board.setPlayPiece(playPiece2);
  board = board.setPlayPiece(playPiece3);
  board = board.setPlayPiece(playPiece4);

  expect(() => board.completedPlayPieces()).toThrow();

  try {
    board.completedPlayPieces();
  } catch (ex) {
    console.log(`${stringify(ex)}`);
  }
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


