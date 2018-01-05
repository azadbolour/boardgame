{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import qualified Data.Maybe as Maybe

import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Board as Board

import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseGrid :: Grid (Maybe Piece)
baseGrid = Grid [
--        0        1        2        3        4
      [Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [pce 'C', pce 'A', pce 'R', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'O', pce 'N'] -- 2
    , [pce 'E', pce 'A', pce 'R', Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, pce 'E', pce 'X'] -- 4
    , [Nothing, Nothing, Nothing, Nothing, Nothing] -- 5
  ]

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = Maybe.fromMaybe Piece.emptyPiece (Grid.getValue baseGrid r c)
  in Grid.mkPointedGrid cellMaker 5 5

board = Board 5 testGrid


main :: IO ()

main = do
  let crossPlay = CrossWordFinder.findCrossPlay board (Point 1 3) 'D' Axis.Y
  print crossPlay
  return ()

