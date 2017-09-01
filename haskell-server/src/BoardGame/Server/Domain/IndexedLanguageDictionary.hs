--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Server.Domain.IndexedLanguageDictionary (
    IndexedLanguageDictionary
  , mkDictionary
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
import Control.DeepSeq (NFData)
import GHC.Generics (Generic)

import BoardGame.Server.Domain.GameError
import BoardGame.Server.Domain.LanguageDictionary
import BoardGame.Util.WordUtil (WordIndex, DictWord)
import qualified BoardGame.Util.WordUtil as WordUtil
import BoardGame.Util.WordUtil (LetterCombo, DictWord)
import qualified Bolour.Util.MiscUtil as MiscUtil

-- | Basic implementation of language dictionary - indexed on combos.
data IndexedLanguageDictionary = IndexedLanguageDictionary {
    languageCode :: String
  , words :: Set ByteString
  , index :: WordIndex
} deriving (Generic, NFData)

mkWordIndex :: [DictWord] -> WordIndex
mkWordIndex words = MiscUtil.mapFromValueList WordUtil.mkLetterCombo words

instance LanguageDictionary IndexedLanguageDictionary where
  mkDictionary languageCode words =
    IndexedLanguageDictionary languageCode (Set.fromList words) (mkWordIndex words)

  isWord (IndexedLanguageDictionary {words}) word = word `Set.member` words

  getWordPermutations (dictionary @ IndexedLanguageDictionary {index}) combo =
    Maybe.fromMaybe [] (Map.lookup combo index)

  languageCode dictionary @ IndexedLanguageDictionary {languageCode} = languageCode



