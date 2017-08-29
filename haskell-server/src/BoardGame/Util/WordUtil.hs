module BoardGame.Util.WordUtil (
    LetterCombo
  , DictWord
  , WordIndex
  , ByteCount
  , BlankCount
  , mkLetterCombo
  , mergeLetterCombos
  , lookupWordIndex
  , computeCombosGroupedByLength
  ) where

import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as ByteString
import Data.Map (Map)
import qualified Data.Map as Map

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

-- TODO. Implement.
mkLetterCombo permutation = ByteString.empty

-- | Merge two combinations of letters.
mergeLetterCombos :: LetterCombo -> LetterCombo -> LetterCombo

-- TODO. Implement.
mergeLetterCombos combo1 combo2 = ByteString.empty

-- | Look up the words that are permutations of a given combination of letters.
lookupWordIndex :: WordIndex -> LetterCombo -> [DictWord]

-- TODO. Implement.
lookupWordIndex index combo = []

-- | Compute all combinations of a set of letters and group them by length.
computeCombosGroupedByLength :: ByteString -> Map ByteCount [LetterCombo]

-- TODO. Implement.
computeCombosGroupedByLength bytes = Map.empty
