
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import qualified Data.Maybe as Maybe
import qualified Data.ByteString.Lazy.Char8 as BC

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson

data PlayType = WordPlayType | SwapPlayType
  deriving (Eq, Show, Generic)

instance FromJSON PlayType
instance ToJSON PlayType

data BasePlay = BasePlay {
    playType :: PlayType
  , playNumber :: Int
  , playerType :: Int
  , scores :: [Int]
}
  deriving (Eq, Show, Generic)

instance FromJSON BasePlay
instance ToJSON BasePlay

-- | Representation of a single play.
data Play =
  WordPlay {
      basePlay :: BasePlay
    , playPieces :: [Int]
    , replacementPieces :: [Int]
    , deadPoints :: [Int]
  }
  | SwapPlay {
      basePlay :: BasePlay
    , swappedPiece :: Int
    , newPiece :: Int
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
  -> Int
  -> [Int]
  -> [Int]
  -> [Int]
  -> [Int]
  -> Play
mkWordPlay playNumber playerType scores =
  let basePlay = BasePlay WordPlayType playNumber playerType scores
  in WordPlay basePlay

mkSwapPlay ::
     Int
  -> Int
  -> [Int]
  -> Int
  -> Int
  -> Play
mkSwapPlay playNumber playerType scores =
  let basePlay = BasePlay SwapPlayType playNumber playerType scores
  in SwapPlay basePlay


main :: IO ()

play :: Play
play = mkWordPlay 1 1 [0, 0] [0, 0] [0, 0] [0, 0]

main = do
  print $ show play

