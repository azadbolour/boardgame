--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.GameBase (
    GameBase(..)
)
where

import Data.Time (UTCTime)
import qualified Data.ByteString.Lazy.Char8 as BC
import GHC.Generics
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson

import BoardGame.Common.Domain.PieceProviderType (PieceProviderType)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.GridPiece (GridPiece)

data GameBase = GameBase {
  id :: String,
  dimension :: Int,
  trayCapacity :: Int,
  languageCode :: String,
  pieceProviderType :: PieceProviderType,
  pointValues :: [[Int]],
  playerId :: String,
  startTime :: UTCTime,
  endTime :: Maybe UTCTime,
  piecePoints :: [GridPiece],
  initUserPieces :: [Piece],
  initMachinePieces :: [Piece]
}
  deriving (Eq, Show, Generic)

instance FromJSON GameBase
instance ToJSON GameBase


