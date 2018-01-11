--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.CrossWordFinderSpec where

import Test.Hspec
import Data.Maybe (fromJust)
import qualified Data.Maybe as Maybe

import Bolour.Grid.Grid (Grid, Grid(Grid))
import qualified Bolour.Grid.Grid as Grid
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import Bolour.Grid.GridValue (GridValue(GridValue))
import qualified Bolour.Grid.GridValue as GridValue
import qualified BoardGame.Server.Domain.Board as Board

import Bolour.Grid.Point (Point, Point(Point))
import qualified Bolour.Grid.Point as Point
import qualified Bolour.Grid.Point as Axis
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseGrid :: [[Maybe Piece]]
baseGrid = [
--        0        1        2        3        4        5
      [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [pce 'C', pce 'A', pce 'R', Nothing, Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'O', pce 'N', Nothing] -- 2
    , [pce 'E', pce 'A', pce 'R', Nothing, Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, pce 'E', pce 'X', Nothing] -- 4
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 5
  ]

-- testGrid :: Grid GridPiece
-- testGrid =
--   let cellMaker r c = Maybe.fromMaybe Piece.emptyPiece (baseGrid !! r !! c)
--   in Grid.mkPointedGrid cellMaker 6 6

-- board = Board 6 testGrid
board = Board.mkBoardFromPieces baseGrid 6

findExpectedCrossPlay board point ch axis = fromJust $ CrossWordFinder.findCrossPlay board point ch axis

spec :: Spec
spec = do
  describe "find single cross play" $ do
    it "should find cross play with next neighbor" $ do
       let crossPlay = findExpectedCrossPlay board (Point 1 3) 'D' Axis.Y
       length crossPlay `shouldBe` 2
    it "should find cross play with before and after neighbor" $ do
       let crossPlay = findExpectedCrossPlay board (Point 3 4) 'I' Axis.Y
       length crossPlay `shouldBe` 3
       let hd = head crossPlay
       hd `shouldBe` ('N', Point 2 4, False)
       let nxt = head $ tail crossPlay
       nxt `shouldBe` ('I', Point 3 4, True)
    it "should find cross play starting at the board's edge" $ do
       let crossPlay = findExpectedCrossPlay board (Point 0 2) 'O' Axis.Y
       length crossPlay `shouldBe` 2
       let hd = head crossPlay
       hd `shouldBe` ('O', Point 0 2, True)
       let nxt = head $ tail crossPlay
       nxt `shouldBe` ('R', Point 1 2, False)
    it "should find cross play ending at the board's edge" $ do
       let crossPlay = findExpectedCrossPlay board (Point 5 3) 'X' Axis.Y
       length crossPlay `shouldBe` 2
       let hd = head crossPlay
       hd `shouldBe` ('E', Point 4 3, False)
       let nxt = head $ tail crossPlay
       nxt `shouldBe` ('X', Point 5 3, True)
    it "should find cross play with mutiple previous neighbors" $ do
       let crossPlay = findExpectedCrossPlay board (Point 2 5) 'E' Axis.X
       length crossPlay `shouldBe` 3
       let hd = head crossPlay
       hd `shouldBe` ('O', Point 2 3, False)
       let last = crossPlay !! 2
       last `shouldBe` ('E', Point 2 5, True)
  describe "find cross plays" $
    it "should find vertical cross plays" $ do
       let
           point3 = Point 2 3
           point4 = Point 2 4
           piece3 = fromJust $ Board.get board point3
           piece4 = fromJust $ Board.get board point4
           -- GridValue {value = piece3, point = point3} = Board.cell board $ Point 2 3
           -- GridValue {value = piece4, point = point4} = Board.cell board $ Point 2 4
           playPiece1 = PlayPiece (Piece 'L' "") (Point 2 1) True
           playPiece2 = PlayPiece (Piece 'O' "") (Point 2 2) True
           playPiece3 = PlayPiece piece3 point3 False
           playPiece4 = PlayPiece piece4 point4 False
           playPiece5 = PlayPiece (Piece 'Y' "") (Point 2 5) True
           playPieces = [playPiece1, playPiece2, playPiece3, playPiece4, playPiece5]
           crossPlays = CrossWordFinder.findCrossPlays board playPieces
       print crossPlays
       length crossPlays `shouldBe` 2


