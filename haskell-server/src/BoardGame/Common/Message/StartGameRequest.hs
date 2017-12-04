
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
import BoardGame.Common.Domain.GridValue (GridValue)

data StartGameRequest = StartGameRequest {
    gameParams :: GameParams
  , initGridPieces :: [GridValue Piece]
  , initUserPieces :: [Piece]
  , initMachinePieces :: [Piece]
} deriving (Eq, Show, Generic, NFData)

instance FromJSON StartGameRequest
instance ToJSON StartGameRequest






