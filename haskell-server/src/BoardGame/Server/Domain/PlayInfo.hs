--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Domain.PlayInfo where

-- TODO. Merge the data here into Play.

import BoardGame.Server.Domain.PlayDetails (PlayDetails)
import BoardGame.Server.Domain.Player (PlayerType(..))

-- | Master record of a play.
data PlayInfo = PlayInfo {
    number :: Int
  , turn :: PlayerType
  , details :: PlayDetails
} deriving (Eq, Show)

