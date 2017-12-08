--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Common.Domain.ScoreMultiplier (
    ScoreMultiplier(..)
  ) where

import BoardGame.Common.Domain.ScoreMultiplierType

data ScoreMultiplier = ScoreMultiplier {
  scoreMultiplierType :: ScoreMultiplierType,
  factor :: Int
}



