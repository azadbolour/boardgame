--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.WordDictionary (
    WordDictionary(WordDictionary, languageCode, maxMaskedLetters)
  , mkDictionary
  , validateWord
  , defaultLanguageCode
  , isWord
  , isMaskedWord
  , getWordPermutations
  , getAllWords
  ) where

import Data.Bool (bool)
import Data.Set (Set)
import qualified Data.Set as Set
import qualified Data.Maybe as Maybe
-- import Data.ByteString.Char8 (ByteString)
-- import qualified Data.ByteString.Char8 as BS
import qualified Data.Map as Map

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), throwError)

import BoardGame.Server.Domain.GameError
import BoardGame.Util.WordUtil (LetterCombo, WordIndex, DictWord)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified Bolour.Util.MiscUtil as MiscUtil

english :: String
english = "en"

defaultLanguageCode :: String
defaultLanguageCode = english

-- | A dictionary of words in a given language (identified by language code).
data WordDictionary = WordDictionary {
    languageCode :: String  -- ^ public
  , words :: Set String     -- ^ private
  , index :: WordIndex      -- ^ private
  , maskedWords :: Set String
  , maxMaskedLetters :: Int
}

mkDictionary :: String -> [DictWord] -> Int -> WordDictionary
mkDictionary languageCode words maxMaskedLetters =
  WordDictionary languageCode (Set.fromList words) (mkWordIndex words) (mkMaskedWords words maxMaskedLetters) maxMaskedLetters

mkMaskedWords :: [DictWord] -> Int -> Set String
mkMaskedWords words maxMaskedLetters =
  let list = do
               word <- words
               WordUtil.maskWithBlanks word maxMaskedLetters
  in Set.fromList list

-- | Return all words of the dictionary as a set.
getAllWords :: WordDictionary -> Set String
getAllWords WordDictionary {words} = words

-- | True iff given string represents a word.
isWord :: WordDictionary -> String -> Bool
isWord WordDictionary {words} word = word `Set.member` words

isMaskedWord :: WordDictionary -> String -> Bool
isMaskedWord WordDictionary {maskedWords} masked = masked `Set.member` maskedWords

-- | Right iff given string represents a word.
validateWord :: (MonadError GameError m, MonadIO m) => WordDictionary -> String -> m String
validateWord languageDictionary word = do
  let valid = isWord languageDictionary word
  bool (throwError $ InvalidWordError $ word) (return word) valid

-- | Look up the words that are permutations of a given combination of letters.
getWordPermutations ::
     WordDictionary -- ^ The dictionary.
  -> LetterCombo -- ^ Combinations of letters represented as a SORTED byte string.
  -> [DictWord]  -- ^ Permutations of the given combination that are in the dictionary.
getWordPermutations (dictionary @ WordDictionary {index}) combo =
  Maybe.fromMaybe [] (Map.lookup combo index)

-- Private functions.

mkWordIndex :: [DictWord] -> WordIndex
mkWordIndex words = MiscUtil.mapFromValueList WordUtil.mkLetterCombo words



