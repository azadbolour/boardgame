--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.Play (
    Play(..)
  , BasePlay(..)
  , mkWordPlay
  , mkSwapPlay
)
where

import qualified Data.ByteString.Lazy.Char8 as BC

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson

import Bolour.Plane.Domain.Point (Point)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Server.Domain.Player (PlayerType(..))
import BoardGame.Common.Domain.PlayPiece (PlayPiece)

data PlayType = WordPlayType | SwapPlayType
  deriving (Eq, Show, Generic)

instance FromJSON PlayType
instance ToJSON PlayType

data BasePlay = BasePlay {
    playType :: PlayType
  , playNumber :: Int
  , playerType :: PlayerType
  , scores :: [Int]
}
  deriving (Eq, Show, Generic)

instance FromJSON BasePlay
instance ToJSON BasePlay

-- | Representation of a single play.
data Play =
  WordPlay {
      basePlay :: BasePlay
    , playPieces :: [PlayPiece]
    , replacementPieces :: [Piece]
    , deadPoints :: [Point]
  }
  | SwapPlay {
      basePlay :: BasePlay
    , swappedPiece :: Piece
    , newPiece :: Piece
  }
  deriving (Eq, Show, Generic)

instance FromJSON Play
instance ToJSON Play

encode :: Play -> String
encode play = BC.unpack $ Aeson.encode play

decode :: String -> Maybe Play
decode encoded = Aeson.decode $ BC.pack encoded

mkWordPlay ::
     Int
  -> PlayerType
  -> [Int]
  -> [PlayPiece]
  -> [Piece]
  -> [Point]
  -> Play
mkWordPlay playNumber playerType scores =
  let basePlay = BasePlay WordPlayType playNumber playerType scores
  in WordPlay basePlay

mkSwapPlay ::
     Int
  -> PlayerType
  -> [Int]
  -> Piece
  -> Piece
  -> Play
mkSwapPlay playNumber playerType scores =
  let basePlay = BasePlay SwapPlayType playNumber playerType scores
  in SwapPlay basePlay


