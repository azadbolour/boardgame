--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.ScorerSpec where

import Test.Hspec
import Data.Maybe (fromJust)
import qualified Data.Maybe as Maybe

import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece), MoveInfo)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.ScoreMultiplier (ScoreMultiplier, ScoreMultiplier(ScoreMultiplier))
import qualified BoardGame.Common.Domain.ScoreMultiplier as ScoreMultiplier
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Board as Board

import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import qualified BoardGame.Server.Domain.Scorer as Scorer
import BoardGame.Server.Domain.Scorer (Scorer)

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

dimension = 5
trayCapacity = 3

baseGrid :: Grid (Maybe Piece)
baseGrid = Grid [
--        0        1        2        3        4
      [Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [pce 'C', pce 'A', pce 'R', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'O', pce 'N'] -- 2
    , [pce 'E', pce 'A', pce 'R', Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, pce 'E', pce 'X'] -- 4
  ]

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = Maybe.fromMaybe Piece.emptyPiece (Grid.getValue baseGrid r c)
  in Grid.mkPointedGrid cellMaker dimension dimension

board = Board dimension testGrid

scorer = Scorer.mkScorer dimension trayCapacity
scoreWord = Scorer.scoreWord scorer
scorePlay = Scorer.scorePlay scorer

wt = Piece.letterWorth

toPlayPiece :: MoveInfo -> PlayPiece
toPlayPiece (ch, point, moved) = PlayPiece (Piece ch "") point moved
-- Note: piece id is not involved in scoring.

spec :: Spec
spec = do
  describe "get score multipliers" $
    it "should get correct multiplers" $ do
       let mult @ ScoreMultiplier {factor} = ScoreMultiplier.scoreMultiplier (Point 7 4) 9
       print mult
       factor `shouldBe` 3
  describe "calculate word scores" $ do
    it "should find score for 1 move play" $ do
       let wordInfo = [
                  ('N', Point 2 4, False)
                , ('I', Point 3 4, True)
                , ('X', Point 4 4, False)
              ]
           score = scoreWord wordInfo
       print score
       score `shouldBe` (wt 'N') + 2 * (wt 'I') + (wt 'X')
    it "should find score for 1 move play" $ do
       let wordInfo = [
                  ('S', Point 2 1, True)
                , ('O', Point 2 2, True)
                , ('O', Point 2 3, False)
                , ('N', Point 2 4, False)
              ]
           score = scoreWord wordInfo
       print score
       score `shouldBe` 2 * (wt 'S' + wt 'O' + wt 'O' + wt 'N')
  describe "calculate play scores" $ do
    it "should find play score with no cross words" $ do
       let wordInfo = [
                  ('N', Point 2 4, False)
                , ('I', Point 3 4, True)
                , ('X', Point 4 4, False)
              ]
           playPieces = toPlayPiece <$> wordInfo
           score = scorePlay board playPieces
       print score
       score `shouldBe` (wt 'N') + 2 * (wt 'I') + (wt 'X')
    it "should find play score with cross words" $ do
       let wordInfo = [
                  ('S', Point 2 1, True)
                , ('O', Point 2 2, True)
                , ('O', Point 2 3, False)
                , ('N', Point 2 4, False)
              ]
           playPieces = toPlayPiece <$> wordInfo
           score = scorePlay board playPieces
       print score
       let wordScore = 2 * (wt 'S' + wt 'O' + wt 'O' + wt 'N')
           asaCrossScore = wt 'A' + wt 'S' + wt 'A'
           rorCrossScore = 2 * (wt 'R' + wt 'O' + wt 'R')
           totalScore = wordScore + asaCrossScore + rorCrossScore
       score `shouldBe` totalScore





