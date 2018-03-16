--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Language.Domain.DictionaryCache (
    DictionaryCache
  , mkCache
  , insert
  , lookup
  , lookupDefault
) where

import Prelude hiding (lookup)
import qualified Data.Char as Char

import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import Bolour.Util.Cache (Cache)
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import Bolour.Language.Domain.WordDictionary (WordDictionary)
import qualified Bolour.Language.Domain.WordDictionary as Dict

-- | Cache of language dictionaries identified by language code.
data DictionaryCache = DictionaryCache {
  cache :: Cache String WordDictionary
}

-- | Factory function (constructor is private).
mkCache :: Int -> IO DictionaryCache
mkCache capacity = do
  theCache <- Cache.mkCache capacity
  return $ DictionaryCache theCache

insert :: String -> WordDictionary -> DictionaryCache -> IOExceptT String ()
insert languageCode dictionary DictionaryCache {cache} =
  Cache.insert languageCode dictionary cache

-- Look up a dictionary by language code.
lookup :: String -> DictionaryCache -> IOExceptT String WordDictionary
lookup languageCode (dictionaryCache @ DictionaryCache {cache}) = do
  let code = if null languageCode then Dict.defaultLanguageCode else languageCode
  Cache.lookup code cache

-- Get the dictionary for the default language (defined in WordDictionary).
lookupDefault :: DictionaryCache -> IOExceptT String WordDictionary
lookupDefault = lookup Dict.defaultLanguageCode


