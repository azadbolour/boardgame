--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

-- | Class of language dictionaries.
module BoardGame.Server.Domain.LanguageDictionary (
    LanguageDictionary
  , mkDictionary
  , isWord
  , getWordPermutations
  , languageCode
  , defaultLanguageCode
  ) where

import Data.ByteString.Char8 (ByteString)
import Control.DeepSeq (NFData)

import BoardGame.Util.WordUtil (LetterCombo, DictWord)

class NFData dictionary => LanguageDictionary dictionary where

  -- | Create a dictionary for a given language code.
  mkDictionary ::
       String         -- ^ language code
    -> [DictWord]     -- ^ words
    -> dictionary

  -- | True iff given string represents a word.
  isWord ::
       dictionary
    -> ByteString   -- ^ purported word
    -> Bool

  -- | Look up the words that are permutations of a given combination of letters.
  getWordPermutations ::
       dictionary
    -> LetterCombo -- ^ combination of letters represented as a SORTED byte string
    -> [DictWord]  -- ^ dictionary words that are rearrangements of the given letters

  -- | Get the language code of the dictionary: where the country code if any
  --   is underscore-separated, e.g., en_US.
  languageCode ::
       dictionary
    -> String       -- ^ code identifying the dictionary language

english :: String
english = "en"

defaultLanguageCode :: String
defaultLanguageCode = english



