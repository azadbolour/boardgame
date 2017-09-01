--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.DictionaryCache (
    DictionaryCache
  , mkCache
  , lookup
  , lookupDefault
) where

import Prelude hiding (lookup)
import qualified Data.Char as Char
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS

import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import Bolour.Util.Cache (Cache)
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Server.Domain.LanguageDictionary as DictClass
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary)

import qualified Paths_boardgame as ResourcePaths

-- | Cache of efficient language dictionaries identified by language code
--   and stored as files in a given directory.
data (LanguageDictionary dictionary) => DictionaryCache dictionary =
  DictionaryCache { -- private constructor
    dictionaryDirectory :: String -- private
  , cache :: Cache String dictionary -- private
}

-- | Factory function (constructor is private).
mkCache :: LanguageDictionary dictionary =>
     String
  -> Int
  -> IO (DictionaryCache dictionary)
mkCache dictionaryDirectory capacity = do
  theCache <- Cache.mkCache capacity
  return $ DictionaryCache dictionaryDirectory theCache

-- Look up a dictionary by language code.
lookup :: LanguageDictionary dictionary =>
     String
  -> DictionaryCache dictionary
  -> IOExceptT String dictionary
lookup languageCode (dictionaryCache @ DictionaryCache {dictionaryDirectory, cache}) = do
  let code = if null languageCode then DictClass.defaultLanguageCode else languageCode
  Cache.lookup code cache `catchError` (\_ -> readDictionaryFile dictionaryCache code)

-- Get the dictionary for the default language (defined in IndexedLanguageDictionary).
lookupDefault :: LanguageDictionary dictionary =>
     DictionaryCache dictionary
  -> IOExceptT String dictionary
lookupDefault = lookup DictClass.defaultLanguageCode

-- Private functions.

readDictionaryFile :: LanguageDictionary dictionary =>
     DictionaryCache dictionary
  -> String
  -> IOExceptT String dictionary
readDictionaryFile DictionaryCache {dictionaryDirectory, cache} languageCode = do
  path <- liftIO $ mkDictionaryPath dictionaryDirectory languageCode
  lines <- ExceptT $ catchAny (readDictionaryInternal path) showException
  let words = BS.map Char.toUpper <$> lines
      dictionary = Dict.mkDictionary languageCode words
  Cache.insert languageCode dictionary cache
  return dictionary

readDictionaryInternal :: String -> IOEither String [ByteString]
readDictionaryInternal path = do
  -- print $ "reading file: " ++ path
  contents <- BS.readFile path
  return $ Right $ BS.lines contents

mkDictionaryPath :: String -> String -> IO String
mkDictionaryPath dictionaryDirectory languageCode = do
  directory <- if null dictionaryDirectory
    then do
          -- no explicit dictionary path provided
          -- default to look up dictionaries as program resources
          -- in the resources 'data' directory
          dataDir <- ResourcePaths.getDataDir
          return $ dataDir ++ "/data"
    else return dictionaryDirectory
  let fileName = languageCode ++ "-words.txt"
  return $ directory ++ "/" ++ fileName

showException :: SomeException -> IOEither String [ByteString]
showException someExc = return $ Left $ show someExc


