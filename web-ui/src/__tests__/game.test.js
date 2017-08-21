/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import {mkBoard, mkEmptyBoard} from "../domain/Board";
import {mkGridPiece} from "../domain/GridPiece";
import {mkPiece} from "../domain/Piece";
import * as Piece from "../domain/Piece";
import {mkPoint} from "../domain/Point";
import * as Point from "../domain/Point";
import {mkTray} from "../domain/Tray";
import {mkGame} from "../domain/Game";
import {mkCommittedPlayPiece} from "../domain/PlayPiece";
import GameParams from "../domain/GameParams";

let mkDefaultGame = function(dimension) {
  let gameParams = GameParams.defaultParams();
  gameParams.dimension = dimension;
  let center = Math.floor(dimension/2);
  let board = mkEmptyBoard(dimension);
  let centerPiece = mkPiece('A', 'initial');
  let centerPoint = mkPoint(center, center);
  let centerPlayPiece = mkCommittedPlayPiece(centerPiece, centerPoint);

  let $board = board.setPlayPiece(centerPlayPiece);
  let trayPieces = [
    mkPiece('B', 'trayB'),
    mkPiece('C', 'trayC'),
  ];
  let tray = mkTray(2, trayPieces);
  let game = mkGame(gameParams, "1234", $board, tray, [0, 0]);
  return game;
};

let moveFromTray = function(game, point) {
  let piece = game.tray.piece(0);
  let move = mkGridPiece(piece, point);
  let $game = game.applyUserMove(move);
  return [$game, move];
};

let moveFromBoard = function(game, piece, point) {
  let move = mkGridPiece(piece, point);
  let $game = game.applyUserMove(move);
  return [$game, move];
};

test('add moves to game', () => {
  let game = mkDefaultGame(5);
  let center = Math.floor(game.dimension/2);
  let row = center;
  let col = center + 2;
  let destPoint = mkPoint(row, col);
  let [$game, move] = moveFromTray(game, destPoint);
  let destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  let dest = destPlayPieces[0].point;
  expect(dest.row).toBe(row);
  expect(dest.col).toBe(col);
  expect($game.board.numMoves()).toBe(1);
});

test('revert a move', () => {
  let game = mkDefaultGame(5);
  let center = Math.floor(game.dimension/2);
  let row = center;
  let col = center + 2;
  let destPoint = mkPoint(row, col);
  let [$game, move] = moveFromTray(game, destPoint);
  let destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  let dest = destPlayPieces[0].point;
  expect(dest.row).toBe(row);
  expect(dest.col).toBe(col);
  expect($game.board.numMoves()).toBe(1);
  let piece = destPlayPieces[0].piece;
  $game = $game.revertMove(piece, dest);
  destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(0);
});

test('move piece from the board along the same line', () => {
  let game = mkDefaultGame(5);
  let center = Math.floor(game.dimension/2);
  let row = center;
  let col = center + 2;
  let destPoint = mkPoint(row, col);
  let [$game, move] = moveFromTray(game, destPoint);
  let destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  let dest = destPlayPieces[0].point;
  expect(Point.eq(dest, destPoint));
  expect($game.board.numMoves()).toBe(1);
  let piece = destPlayPieces[0].piece;
  let inlineDestPoint = mkPoint(row, center - 1);
  [$game, move] = moveFromBoard(game, piece, destPoint);
  destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  dest = destPlayPieces[0].point;
  expect(Point.eq(dest, inlineDestPoint));
  expect(Piece.eq(destPlayPieces[0].piece, piece));
});

test('move piece from the board to cross line', () => {
  let game = mkDefaultGame(5);
  let center = Math.floor(game.dimension/2);
  let row = center;
  let col = center + 2;
  let destPoint = mkPoint(row, col);
  let [$game, move] = moveFromTray(game, destPoint);
  let destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  let dest = destPlayPieces[0].point;
  expect(Point.eq(dest, destPoint));
  expect($game.board.numMoves()).toBe(1);
  let piece = destPlayPieces[0].piece;
  let crossLineDestPoint = mkPoint(row - 1, center);
  [$game, move] = moveFromBoard(game, piece, destPoint);
  destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  dest = destPlayPieces[0].point;
  expect(Point.eq(dest, crossLineDestPoint));
  expect(Piece.eq(destPlayPieces[0].piece, piece));
});

test('move of a committed board piece is disallowed', () => {
  let game = mkDefaultGame(5);
  let center = Math.floor(game.dimension/2);
  let row = center;
  let col = center + 2;
  let destPoint = mkPoint(row, col);
  let [$game, move] = moveFromTray(game, destPoint);
  let destPlayPieces = $game.getUserMovePlayPieces();
  expect(destPlayPieces.length).toBe(1);
  let dest = destPlayPieces[0].point;
  expect(Point.eq(dest, destPoint));
  let piece = destPlayPieces[0].piece;
  expect(Piece.eq(piece, move.piece));

  let centerPoint = mkPoint(center, center);
  let centerPlayPiece = $game.board.getPlayPiece(centerPoint);
  expect(centerPlayPiece.moved).toBe(false);

  let to = mkPoint(center, center + 1);
  [$game, move] = moveFromBoard($game, centerPlayPiece.piece, to);
  let illegalMoveToPlayPiece = $game.board.getPlayPiece(to);
  expect(illegalMoveToPlayPiece.isFree()).toBe(true);
  expect(illegalMoveToPlayPiece.moved).toBe(false);
  let finalCenterPlayPiece = $game.board.getPlayPiece(centerPoint);
  expect(Piece.eq(finalCenterPlayPiece.piece, centerPlayPiece.piece)).toBe(true);
});

// TODO. Move piece several times.

