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

-- TODO. Create tests for the scorer module.
-- Pay particular attention to representation of empty cells in the implementation.
-- Then connect this module to the rest of the application and use it to compute scores.
module BoardGame.Server.Domain.Scorer (
    Scorer
  , Scorer(scorePlay, scoreWord)
  , mkScorer
  ) where

import Data.Maybe (fromJust)
import BoardGame.Common.Domain.ScoreMultiplier (ScoreMultiplier, ScoreMultiplier(ScoreMultiplier), noMultiplier)
import qualified BoardGame.Common.Domain.ScoreMultiplier as ScoreMultiplier
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Point (Point)
import BoardGame.Common.Domain.PlayPiece (PlayPiece, PlayPiece(PlayPiece), MoveInfo)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.Grid (Grid)
import BoardGame.Server.Domain.Board (Board)
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import qualified BoardGame.Common.Domain.Grid as Grid

bonus = 50

data Scorer = Scorer {
    scorePlay :: Board -> [PlayPiece] -> Int
  , scoreWord :: [(Char, Point, Bool)] -> Int
}

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
      wordScore = calcWordScore $ PlayPiece.toMoveInfo <$> playPieces
  in wordScore + crossWordsScore

doScoreWord :: Int -> Int -> Grid ScoreMultiplier -> [MoveInfo] -> Int
doScoreWord dimension trayCapacity multGrid moves =
  let points = (\(_, point, _) -> point) <$> moves
      multipliers = Grid.cell multGrid <$> points
      moveMultipliers = moves `zip` multipliers -- List[((letter, point, moved), scoreMultiplier)]

      -- Get the base letter score.
      baseScore = scoreLetters moveMultipliers

      -- Multiply by the total word multiplier factors for new pieces.
      calcWordMultFactor ((_, _, moved), mult @ ScoreMultiplier {factor}) =
        if moved && ScoreMultiplier.isWordMultiplier mult then factor else 0
      sumWordFactors = max 1 (sum $ calcWordMultFactor <$> moveMultipliers)
      wordScore = sumWordFactors * baseScore

      -- Add the full tray play bonus.
      numMoves = length $ filter (\(_, _, moved) -> moved) moves
      bonusScore = if numMoves == trayCapacity then bonus else 0
      score = wordScore + bonusScore
  in score

scoreLetters :: [(MoveInfo, ScoreMultiplier)] -> Int
scoreLetters moveMultipliers =
  sum (letterScore <$> moveMultipliers)
    where
      letterScore ((letter, _, moved), mult @ ScoreMultiplier {factor}) =
        let w = Piece.letterWorth letter
            useFactor = ScoreMultiplier.isLetterMultiplier mult
        in w * if moved && useFactor then factor else 1
