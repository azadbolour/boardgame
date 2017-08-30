--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Util.WordUtil (
    LetterCombo
  , DictWord
  , WordIndex
  , ByteCount
  , BlankCount
  , mkLetterCombo
  , mergeLetterCombos
  , lookupWordIndex
  , computeCombos
  , computeCombosGroupedByLength
  ) where

import Data.ByteString.Char8
import qualified Data.ByteString.Char8 as BS
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.Maybe as Maybe

import qualified Bolour.Util.MiscUtil as MiscUtil

-- | Combinations of letters (with repetition) sorted in a byte string.
type LetterCombo = ByteString

-- | A dictionary word.
type DictWord = ByteString

-- | Index of words.
--   Key is a combination of letters.
--   Value is permutations of the letters in the key that are actual words.
type WordIndex = Map LetterCombo [DictWord]

type ByteCount = Int
type BlankCount = Int

-- | Make a permutation of some letters, create the corresponding combination of those letters.
--   In our representation just sort the letters.
mkLetterCombo :: ByteString -> LetterCombo
mkLetterCombo permutation = BS.sort permutation

-- | Merge two combinations of letters.
mergeLetterCombos :: LetterCombo -> LetterCombo -> LetterCombo
mergeLetterCombos combo1 combo2 = BS.sort $ BS.append combo1 combo2

-- | Look up the words that are permutations of a given combination of letters.
lookupWordIndex :: LetterCombo -> WordIndex -> [DictWord]
lookupWordIndex letters wordIndex = Maybe.fromMaybe [] (Map.lookup letters wordIndex)

-- TODO. Eliminate duplicates for maximum performance.

-- | Compute all combinations of a set of letters and group them by length.
computeCombosGroupedByLength :: ByteString -> Map ByteCount [LetterCombo]
computeCombosGroupedByLength bytes =
  let combos = computeCombos bytes
  in MiscUtil.mapFromValueList BS.length combos

computeCombos :: ByteString -> [LetterCombo]
computeCombos bytes = BS.sort <$> computeCombosUnsorted bytes

computeCombosUnsorted :: ByteString -> [ByteString]
computeCombosUnsorted bytes
  | BS.null bytes = [BS.empty]
  | otherwise =
      let h = BS.head bytes
          t = BS.tail bytes
          tailCombos = computeCombosUnsorted t
          combosWithHead = BS.cons h <$> tailCombos
      in tailCombos ++ combosWithHead


