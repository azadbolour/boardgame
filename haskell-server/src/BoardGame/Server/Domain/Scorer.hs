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
    scorePlay
  ) where

import BoardGame.Common.Domain.ScoreMultiplier (ScoreMultiplier, noMultiplier)
import qualified BoardGame.Common.Domain.ScoreMultiplier as ScoreMultiplier
import BoardGame.Common.Domain.Point (Point)
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Server.Domain.Board (Board)
import BoardGame.Server.Domain.Grid (Grid, mkGrid)

bonus = 50

multiplierGrid :: Int -> Grid ScoreMultiplier
multiplierGrid dimension = mkGrid (\row col -> ScoreMultiplier.noMultiplier) dimension dimension

scorePlay :: Board -> [PlayPiece] -> Int
scorePlay board plaoyPieces = 0

scoreWord :: [(Char, Point, Bool)] -> Int
scoreWord playData = 0