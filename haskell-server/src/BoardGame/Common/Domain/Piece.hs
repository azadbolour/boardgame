--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.Piece (
    Piece(..)
  , mkPiece
  , isPiece
  , noPiece
  , noPieceValue
  , isNoPiece
  , mkRandomPiece
  , mkRandomPieces
  , eqValue
  , leastFrequentLetter
  , randomLetter
  , mkRandomPieceForId
) where

import System.Random
import Data.Char
import Data.List
import GHC.Generics (Generic)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import Bolour.Util.MiscUtil as Misc

-- TODO. The value of a piece should be a single character and upper case.
-- TODO. Should validate value of piece, and maybe change its type to Char.

-- |A game piece.
data Piece = Piece {
    value :: Char,      -- ^ The letter - an upper case alpha character.
    pieceId :: String     -- ^ The unique id of the piece.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON Piece
instance ToJSON Piece

-- |A game cell. Nothing means there is no piece at the cell.
-- type Cell = Maybe Piece

noPieceValue = '\0'
noPiece = Piece noPieceValue "-1"
isNoPiece :: Piece -> Bool
isNoPiece = (== noPiece)
isPiece :: Piece -> Bool
isPiece = (/= noPiece)


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

-- | Letter frequencies to use in obtaining a piece with a random letter.
frequencies = [
  ('A', 10),
  ('B', 3),
  ('C', 3),
  ('D', 3),
  ('E', 20),
  ('F', 3),
  ('G', 3),
  ('H', 5),
  ('I', 8),
  ('J', 3),
  ('K', 3),
  ('L', 4),
  ('M', 4),
  ('N', 5),
  ('O', 10),
  ('P', 3),
  ('Q', 1),
  ('R', 6),
  ('S', 15),
  ('T', 3),
  ('U', 7),
  ('V', 3),
  ('W', 3),
  ('X', 2),
  ('Y', 5),
  ('Z', 2)
  ]

-- | The distribution function of the letters.
distribution :: [(Char, Int)]
distribution = tail $ scanl' (\(l1, f1) (l2, f2) -> (l2, f1 + f2)) ('a', 0) frequencies

maxDistribution = snd $ last distribution

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

