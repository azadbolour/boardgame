--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- TODO. mkPiece is really deprecated. But let's not clutter the build output for now.
-- {-# DEPRECATED mkPiece "Use appropriate pieceOf function of appropriate PieceProvider." #-}

module BoardGame.Common.Domain.Piece (
    Piece(..)
  , mkPiece
  , eqValue
  , mkRandomPiece
  , mkRandomPieces
  , mkRandomPieceForId
  , leastFrequentLetter
  , randomLetter
  , mkRandomPieceForId
  , frequencies
  , normalizedFrequencies
  , worth
  , letterWorth
  , piecesToString
) where

import System.Random
import Data.Char
import Data.List
import qualified Data.Maybe as Maybe
import qualified Data.Map as Map
import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import Bolour.Util.MiscUtil as Misc

-- |A game piece.
data Piece = Piece {
    value :: Char,      -- ^ The letter - an upper case alpha character.
    id :: String     -- ^ The unique id of the piece.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON Piece
instance ToJSON Piece

piecesToString :: [Piece] -> String
piecesToString pieces = value <$> pieces

asciiA :: Int
asciiA = ord 'A'

-- | Create a piece with given value and a unique id.
mkPiece :: Char -> IO Piece
mkPiece letter = do
  id <- Misc.mkUuid
  return $ Piece letter id

mkRandomPiece :: IO Piece
mkRandomPiece = mkRandomPieceInternal 1

mkRandomPieceForId :: String -> IO Piece
mkRandomPieceForId id = do
  value <- randomLetter
  return $ Piece value id

-- | Create a set of random pieces of upper case letters
--   with equal probability for each letter.
mkRandomPieces :: Int -> IO [Piece]
mkRandomPieces num = sequence $ mkRandomPieceInternal <$> [1 .. num]

-- | Private helper function for creating a random piece.
--   The dummy int parameter is for convenience of mkRandomPieces.
mkRandomPieceInternal :: Int -> IO Piece
mkRandomPieceInternal _ = do
  id <- Misc.mkUuid
  offset <- randomRIO (0, 25)
  let asciiValue = asciiA + offset
  let value = chr asciiValue
  return $ Piece value id

eqValue :: Piece -> Piece -> Bool
eqValue p1 p2 = (value p1) == (value p2)

-- | Tile frequencies for 15x15 board.
frequencies = [
    ('A', 81),
    ('B', 15),
    ('C', 28),
    ('D', 42),
    ('E', 127),
    ('F', 22),
    ('G', 20),
    ('H', 61),
    ('I', 70),
    ('J', 2),
    ('K', 8),
    ('L', 40),
    ('M', 24),
    ('N', 67),
    ('O', 80),
    ('P', 19),
    ('Q', 1),
    ('R', 60),
    ('S', 63),
    ('T', 91),
    ('U', 28),
    ('V', 10),
    ('W', 23),
    ('X', 2),
    ('Y', 20),
    ('Z', 1)
  ]

frequencyMap :: Map.Map Char Int
frequencyMap = Map.fromList frequencies

worths :: Map.Map Char Int
worths = Map.fromList [
    ('A', 1),
    ('B', 1),
    ('C', 1),
    ('D', 1),
    ('E', 1),
    ('F', 1),
    ('G', 1),
    ('H', 1),
    ('I', 1),
    ('J', 1),
    ('K', 1),
    ('L', 1),
    ('M', 1),
    ('N', 1),
    ('O', 1),
    ('P', 1),
    ('Q', 1),
    ('R', 1),
    ('S', 1),
    ('T', 1),
    ('U', 1),
    ('V', 1),
    ('W', 1),
    ('X', 1),
    ('Y', 1),
    ('Z', 1)
  ]

-- | The distribution function of the letters.
distribution :: [(Char, Int)]
distribution = tail $ scanl' (\(l1, f1) (l2, f2) -> (l2, f1 + f2)) ('a', 0) frequencies

maxDistribution = snd $ last distribution

worth :: Piece -> Int
worth Piece { value } = letterWorth value

letterWorth :: Char -> Int
letterWorth ch = Maybe.fromJust $ Map.lookup ch worths

-- | Get a random letter according to the letter frequencies.
randomLetter :: IO Char
randomLetter = do
  dist <- randomRIO (0, maxDistribution - 1)
  let Just offset = findIndex ((<) dist . snd) distribution
  let asciiValue = asciiA + offset
  return $ chr asciiValue

-- | Get the frequency of a letter.
findLetterFrequency :: Char -> Maybe Int
findLetterFrequency char = do
  (_, frequency) <- find (\(ch, freq) -> ch == char) frequencies
  return frequency

-- | Get the least frequent letter.
leastFrequentLetter :: String -> Maybe (Char, Int)
leastFrequentLetter s =
  case s of
    [] -> Nothing
    (x:xs) -> do
      freq <- findLetterFrequency x
      leastFrequent' xs $ Just (x, freq)

leastFrequent' :: String -> Maybe (Char, Int) -> Maybe (Char, Int)
leastFrequent' [] least = least
leastFrequent' _ Nothing = Nothing
leastFrequent' (x:xs) (least @ (Just (leastChar, leastFreq))) = do
  freq <- findLetterFrequency x
  let least' = if freq < leastFreq then Just (x, freq) else least
  leastFrequent' xs least'

normalizedFrequencies :: Int -> ((Map.Map Char Int), Int)
normalizedFrequencies roughTotal =
  let factor :: Float = fromIntegral roughTotal / fromIntegral maxDistribution
      normalizer freq = max 1 (round $ fromIntegral freq * factor)
      normalized = normalizer <$> frequencyMap
      total = sum $ Map.elems normalized
  in (normalized, total)
