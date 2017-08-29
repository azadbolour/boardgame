--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.StripMatcherSpec where

import Test.Hspec

import qualified Data.Map as Map
import qualified Data.Maybe as Maybe

import BoardGame.Server.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Server.Domain.Grid as Grid
import BoardGame.Common.Domain.Point (Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Board as Board

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseTestGrid :: Grid (Maybe Piece)
baseTestGrid = Grid [
--        0        1        2        3        4        5
      [Nothing, Nothing, Nothing, pce 'C', Nothing, Nothing] -- 0
    , [Nothing, pce 'A', pce 'C', pce 'E', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'R', Nothing, Nothing] -- 2
    , [Nothing, Nothing, Nothing, pce 'T', pce 'A', pce 'X'] -- 3
    , [Nothing, Nothing, Nothing, pce 'A', Nothing, Nothing] -- 4
    , [Nothing, Nothing, Nothing, pce 'I', Nothing, Nothing] -- 5
  ]

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = Maybe.fromMaybe Piece.noPiece (Grid.getValue baseTestGrid r c)
  in Grid.mkPointedGrid cellMaker 6 6

testBoard = Board 6 6 testGrid

trayCapacity :: Int
trayCapacity = 4

spec :: Spec
spec =
  describe "make strips from board" $
    it "make strips from board" $ do
      let groupedStrips = Board.computePlayableStrips testBoard trayCapacity
          groupedStripsLength3 = Maybe.fromJust $ Map.lookup 3 groupedStrips
      groupedStripsLength3 `shouldSatisfy` (not . Map.null)

