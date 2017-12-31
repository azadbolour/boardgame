--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

-- TODO. Implement Scorer functions.

module BoardGame.Server.Domain.Scorer (
    Scorer
  , Scorer(Scorer)
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
    dimension :: Int
  , trayCapacity :: Int
  , muliplierGrid :: Grid ScoreMultiplier
  , scorePlay :: Board -> [PlayPiece] -> Int
  , scoreWord :: [(Char, Point, Bool)] -> Int
}

mkScorer :: Int -> Int -> Scorer
mkScorer dimension trayCapacity =
  Scorer
    dimension
    trayCapacity
    (mkMultiplierGrid dimension)
    (doScorePlay dimension trayCapacity)
    (doScoreWord dimension trayCapacity)

mkMultiplierGrid :: Int -> Grid ScoreMultiplier
mkMultiplierGrid = ScoreMultiplier.mkMultiplierGrid

doScorePlay :: Int -> Int -> Board -> [PlayPiece] -> Int
doScorePlay dimension trayCapacity board playPieces =
  let crossPlays = CrossWordFinder.findCrossPlays board playPieces
      crossScoreList = doScoreWord dimension trayCapacity <$> filter (\list -> length list > 1) crossPlays
      crossWordsScore = sum crossScoreList
      wordScore = doScoreWord dimension trayCapacity (playPointToMoveData <$> playPieces)
  in wordScore + crossWordsScore

playPointToMoveData :: PlayPiece -> (Char, Point, Bool)
playPointToMoveData (PlayPiece { piece, point, moved }) = (Piece.value piece, point, moved)

doScoreWord :: Int -> Int -> [(Char, Point, Bool)] -> Int
doScoreWord dimension trayCapacity playData = 0