--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

-- TODO. mkPiece is really deprecated. But let's not clutter the build output for now.
-- {-# DEPRECATED mkPiece "Use appropriate pieceOf function of appropriate PieceGen." #-}

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
  , charIsBlank
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
    id :: String     -- ^ The unique id of the piece.
}
  deriving (Eq, Show, Generic, NFData)

instance FromJSON Piece
instance ToJSON Piece

noPieceValue = '\0'
noPiece = Piece noPieceValue "-1"
isNoPiece :: Piece -> Bool
isNoPiece = (== noPiece)
isPiece :: Piece -> Bool
isPiece = (/= noPiece)

charIsBlank :: Char -> Bool
charIsBlank = (== noPieceValue)

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
    ('A', 9),
    ('B', 2),
    ('C', 2),
    ('D', 4),
    ('E', 10),
    ('F', 2),
    ('G', 3),
    ('H', 2),
    ('I', 9),
    ('J', 1),
    ('K', 1),
    ('L', 4),
    ('M', 2),
    ('N', 6),
    ('O', 8),
    ('P', 2),
    ('Q', 1),
    ('R', 6),
    ('S', 4),
    ('T', 6),
    ('U', 4),
    ('V', 2),
    ('W', 2),
    ('X', 1),
    ('Y', 2),
    ('Z', 1)
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

