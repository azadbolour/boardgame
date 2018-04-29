--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.GameInitialPieces (
    GameInitialPieces(..)
)
where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.GridPiece (GridPiece)

data GameInitialPieces = GameInitialPieces {
    initGridPieces :: [GridPiece]
  , initUserPieces :: [Piece]
  , initMachinePieces :: [Piece]
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON GameInitialPieces
instance ToJSON GameInitialPieces
