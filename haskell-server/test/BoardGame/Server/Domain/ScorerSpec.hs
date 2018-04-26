--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.ScorerSpec where

import Test.Hspec

import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece), MoveInfo)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Server.Domain.Board as Board

import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Axis as Axis
import qualified BoardGame.Server.Domain.Scorer as Scorer

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

dimension = 5
trayCapacity = 3

baseGrid :: [[Maybe Piece]]
baseGrid = [
--        0        1        2        3        4
      [Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [pce 'C', pce 'A', pce 'R', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'O', pce 'N'] -- 2
    , [pce 'E', pce 'A', pce 'R', Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, pce 'E', pce 'X'] -- 4
  ]

board = Board.mkBoardFromPieces baseGrid dimension

pointValues :: [[Int]]
pointValues = replicate dimension $ replicate dimension 1

scorer = Scorer.mkScorer pointValues
scorePlay = Scorer.scorePlay scorer

-- wt = Piece.letterWorth

-- toPlayPiece :: MoveInfo -> PlayPiece
-- toPlayPiece (ch, point, moved) = PlayPiece (Piece ch "") point moved
-- -- Note: piece id is not involved in scoring.

playPiece :: Char -> Int -> Int -> Bool -> PlayPiece
playPiece ch row col moved = PlayPiece (Piece ch "") (Point row col) moved

spec :: Spec
spec = do
  describe "calculate scores" $ do
    it "should find score for 1 move play" $ do
       let playPieces = [
                  playPiece 'N' 2 4 False
                , playPiece 'I' 3 4 True
                , playPiece 'X' 4 4 False
              ]
           score = scorePlay playPieces
       score `shouldBe` 1
    it "should find score for 2-move play" $ do
       let playPieces = [
                  playPiece 'S' 2 1 True
                , playPiece 'O' 2 2 True
                , playPiece 'O' 2 3 False
                , playPiece 'N' 2 4 False
              ]
           score = scorePlay playPieces
       score `shouldBe` 2





