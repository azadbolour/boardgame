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
  ) where

import Data.Bool (bool)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS
import qualified Data.Map as Map

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..), throwError)


import BoardGame.Server.Domain.GameError
import BoardGame.Util.WordUtil (WordIndex, DictWord)
import qualified BoardGame.Util.WordUtil as WordUtil

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
mkWordIndex words =
  let keyValue word = (WordUtil.mkLetterCombo word, [word])
  in Map.fromListWith (++) $ keyValue <$> words

mkDummyDictionary :: String -> IndexedLanguageDictionary
mkDummyDictionary languageCode = mkDictionary languageCode []

isWord :: IndexedLanguageDictionary -> String -> Bool
isWord (IndexedLanguageDictionary {words}) word = BS.pack word `Set.member` words

-- TODO. This is a hack.
instance Show IndexedLanguageDictionary where
  show = languageCode

-- | Word exists in the the dictionary.
validateWord :: (MonadError GameError m, MonadIO m) => IndexedLanguageDictionary -> String -> m String
validateWord languageDictionary word = do
  let valid = isWord languageDictionary word
  bool (throwError $ InvalidWordError word) (return word) valid




