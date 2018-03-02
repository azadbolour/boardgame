
--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Message.StartGameRequest (
    StartGameRequest(..)
  )
  where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Common.Domain.Piece (Piece)
import Bolour.Plane.Domain.GridValue (GridValue)

data StartGameRequest = StartGameRequest {
    gameParams :: GameParams
  , initGridPieces :: [GridValue Piece]
  , initUserPieces :: [Piece]
  , initMachinePieces :: [Piece]
  , pointValues :: [[Int]]
} deriving (Eq, Show, Generic, NFData)

instance FromJSON StartGameRequest
instance ToJSON StartGameRequest






