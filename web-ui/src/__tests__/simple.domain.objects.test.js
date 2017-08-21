/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import {stringify} from "../util/Logger";
import * as Piece from '../domain/Piece';
import {mkPiece} from '../domain/Piece';
import {mkPoint} from '../domain/Point';
import * as Point from '../domain/Point';
import {mkGridPiece} from '../domain/GridPiece';
import {mkTray} from '../domain/Tray';
import {mkPlayPiece} from '../domain/PlayPiece';
import * as PlayPiece from '../domain/PlayPiece';

test('test construction', () => {
  let piece = mkPiece('A', "1");
  expect(piece.value).toBe('A');
  let noPiece = Piece.NO_PIECE;
  expect(noPiece.value).toBe('');
  let clonedPiece = piece.clone();
  expect(clonedPiece.pieceId).toBe("1");
  let point = mkPoint(1, 1);
  expect(point.row).toBe(1);
  expect(point.col).toBe(1);
  let gridPiece = mkGridPiece(piece, point);
  expect(gridPiece.piece.value).toBe('A');

  let destPoint = mkPoint(2, 1);
  let move = mkGridPiece(piece, destPoint);
  expect(move.point.row).toBe(2);
});

test('test tray', () => {
  let pieces = [mkPiece('A', "1"), mkPiece('B', "2"), mkPiece('C', "3")];
  let tray = mkTray(4, pieces);
  expect(tray.size()).toBe(3);
  let morePieces = [mkPiece('D', "4"), mkPiece('E', "5")];
  expect(function() {
    tray.addPieces(morePieces);
  }).toThrow();

  let resultTray = tray.removePiece("2");
  expect(tray.size()).toBe(3);
  expect(resultTray.size()).toBe(2);
  expect(stringify(resultTray.mapPieces(p => p.value))).toBe(stringify(['A', 'C']));

});

test('play piece manipulation', () => {
  let piece = mkPiece('A', "1");
  let noPiece = Piece.NO_PIECE;
  let point = mkPoint(1, 1);
  // let filledGridPiece = mkGridPiece(piece, point);
  // let emptyGridPiece = mkGridPiece(noPiece, point);
  let filledPlayPiece = mkPlayPiece(piece, point, !PlayPiece.MOVED);
  let emptyPlayPiece = mkPlayPiece(noPiece, point, !PlayPiece.MOVED);

  expect(emptyPlayPiece.isFree()).toBe(true);
  expect(filledPlayPiece.isFree()).toBe(false);

  let movedIn = emptyPlayPiece.setMovedIn(piece);
  expect(Piece.eq(movedIn.piece, piece)).toBe(true);
  expect(Point.eq(movedIn.point, emptyPlayPiece.point)).toBe(true);
  expect(movedIn.moved).toBe(true);
});

test('piece', () => {
  let piece1 = Piece.NO_PIECE;
  let piece2 = Piece.NO_PIECE;
  expect(Piece.eq(piece1, piece2)).toBe(true);
});

