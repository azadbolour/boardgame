--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- TODO. Implement Scorer functions.

module BoardGame.Server.Domain.Scorer (
    Scorer
  , Scorer(scorePlay, scoreWord)
  , mkScorer
  ) where

import BoardGame.Common.Domain.ScoreMultiplier (ScoreMultiplier, noMultiplier)
import qualified BoardGame.Common.Domain.ScoreMultiplier as ScoreMultiplier
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Point (Point)
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece))
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.Grid (Grid)
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
-- import qualified BoardGame.Common.Domain.Grid as Grid

bonus = 50

data Scorer = Scorer {
    scorePlay :: Board -> [PlayPiece] -> Int
  , scoreWord :: [(Char, Point, Bool)] -> Int
}

-- TODO. Move MoveInfo to PlayPiece so it can be shared with CrossWordFinder.
type MoveInfo = (Char, Point, Bool)

mkScorer :: Int -> Int -> Scorer
mkScorer dimension trayCapacity =
  let multGrid = ScoreMultiplier.mkMultiplierGrid dimension
  in Scorer
       (doScorePlay dimension trayCapacity multGrid)
       (doScoreWord dimension trayCapacity multGrid)

doScorePlay :: Int -> Int -> Grid ScoreMultiplier -> Board -> [PlayPiece] -> Int
doScorePlay dimension trayCapacity multGrid board playPieces =
  let crossPlays = CrossWordFinder.findCrossPlays board playPieces
      calcWordScore :: [MoveInfo] -> Int = doScoreWord dimension trayCapacity multGrid
      isCrossWordPlay :: [MoveInfo] -> Bool = (> 1) . length
      crossScores = calcWordScore <$> filter isCrossWordPlay crossPlays
      crossWordsScore = sum crossScores
      wordScore = calcWordScore $ moveInfo <$> playPieces
  in wordScore + crossWordsScore

-- TODO. Move to PlayPiece.
moveInfo :: PlayPiece -> MoveInfo
moveInfo (PlayPiece { piece, point, moved }) = (Piece.value piece, point, moved)

doScoreWord :: Int -> Int -> Grid ScoreMultiplier -> [MoveInfo] -> Int
doScoreWord dimension trayCapacity multGrid playData = 0