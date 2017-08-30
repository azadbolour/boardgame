--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.IndexedLanguageDictionary (
    IndexedLanguageDictionary(..)
  , mkDictionary
  , validateWord
  , defaultLanguageCode
  , mkDummyDictionary
  , isWord
  , getWordPermutations
  , getAllWords
  , getAllWordsAsString
  ) where

import Data.Bool (bool)
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Data.Maybe as Maybe
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS
import qualified Data.Map as Map

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), throwError)

import BoardGame.Server.Domain.GameError
import BoardGame.Util.WordUtil (WordIndex, DictWord)
import qualified BoardGame.Util.WordUtil as WordUtil
import BoardGame.Util.WordUtil (LetterCombo, DictWord)
import qualified Bolour.Util.MiscUtil as MiscUtil

english :: String
english = "en"

defaultLanguageCode :: String
defaultLanguageCode = english

-- | A dictionary of words in a given language.
data IndexedLanguageDictionary = IndexedLanguageDictionary {
    languageCode :: String
  , words :: Set ByteString
  , index :: WordIndex
}

mkDictionary :: String -> [DictWord] -> IndexedLanguageDictionary
mkDictionary languageCode words = IndexedLanguageDictionary languageCode (Set.fromList words) (mkWordIndex words)

mkWordIndex :: [DictWord] -> WordIndex
mkWordIndex words = MiscUtil.mapFromValueList WordUtil.mkLetterCombo words

mkDummyDictionary :: String -> IndexedLanguageDictionary
mkDummyDictionary languageCode = mkDictionary languageCode []

getAllWords :: IndexedLanguageDictionary -> Set ByteString
getAllWords IndexedLanguageDictionary {words} = words

-- TODO. Temporary function during refactoring. Remove.
getAllWordsAsString :: IndexedLanguageDictionary -> [String]
getAllWordsAsString IndexedLanguageDictionary {words} = BS.unpack <$> Set.toList words


isWord :: IndexedLanguageDictionary -> ByteString -> Bool
isWord (IndexedLanguageDictionary {words}) word = word `Set.member` words

-- TODO. This is a hack.
instance Show IndexedLanguageDictionary where
  show = languageCode

-- | Word exists in the the dictionary.
validateWord :: (MonadError GameError m, MonadIO m) => IndexedLanguageDictionary -> ByteString -> m ByteString
validateWord languageDictionary word = do
  let valid = isWord languageDictionary word
  bool (throwError $ InvalidWordError $ BS.unpack word) (return word) valid

-- | Look up the words that are permutations of a given combination of letters.
getWordPermutations ::
     IndexedLanguageDictionary -- ^ The dictionary.
  -> LetterCombo -- ^ Combinations of letters represented as a SORTED byte string.
  -> [DictWord]  -- ^ Permutations of the given combination that are in the dictionary.
getWordPermutations (dictionary @ IndexedLanguageDictionary {index}) combo =
  Maybe.fromMaybe [] (Map.lookup combo index)



