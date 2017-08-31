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
  , lookupDictionary
  , getDefaultDictionary
) where

import qualified Data.Char as Char
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS

import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import Bolour.Util.Cache (Cache(Cache))
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict

import qualified Paths_boardgame as ResourcePaths

-- | Cache of language dictionaries identified by language code.
data DictionaryCache = DictionaryCache { -- private constructor
    dictionaryDirectory :: String -- private
  , cache :: Cache String IndexedLanguageDictionary -- private
}

-- | Factory function (constructor is private).
mkCache :: String -> Int -> IO DictionaryCache
mkCache dictionaryDirectory capacity = do
  theCache <- Cache.mkCache capacity
  return $ DictionaryCache dictionaryDirectory theCache

-- Look up a dictionary by language code.
lookupDictionary :: DictionaryCache -> String -> IOExceptT String IndexedLanguageDictionary
lookupDictionary (dictionaryCache @ DictionaryCache {dictionaryDirectory, cache}) languageCode = do
  let code = if null languageCode then Dict.defaultLanguageCode else languageCode
  Cache.findItem cache code `catchError` (\_ -> readDictionaryFile dictionaryCache code)

-- Get the dictionary for the default language (defined in IndexedLanguageDictionary).
getDefaultDictionary :: DictionaryCache -> IOExceptT String IndexedLanguageDictionary
getDefaultDictionary cache = lookupDictionary cache Dict.defaultLanguageCode

-- Private functions.

readDictionaryFile :: DictionaryCache -> String -> IOExceptT String IndexedLanguageDictionary
readDictionaryFile DictionaryCache {dictionaryDirectory, cache} languageCode = do
  path <- liftIO $ mkDictionaryPath dictionaryDirectory languageCode
  lines <- ExceptT $ catchAny (readDictionaryInternal path) showException
  let words = BS.map Char.toUpper <$> lines
      dictionary = Dict.mkDictionary languageCode words
  Cache.putItem cache languageCode dictionary
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


