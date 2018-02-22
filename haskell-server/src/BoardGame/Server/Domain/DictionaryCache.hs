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
-- import Data.ByteString.Char8 (ByteString)
-- import qualified Data.ByteString.Char8 as BS

import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import Bolour.Util.Cache (Cache)
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import BoardGame.Server.Domain.WordDictionary (WordDictionary)
import qualified BoardGame.Server.Domain.WordDictionary as Dict

import qualified Paths_boardgame as ResourcePaths

-- | Cache of language dictionaries identified by language code.
data DictionaryCache = DictionaryCache {
    dictionaryDirectory :: String
  , maxMaskedLetters :: Int
  , cache :: Cache String WordDictionary
}

-- | Factory function (constructor is private).
mkCache :: String -> Int -> Int -> IO DictionaryCache
mkCache dictionaryDirectory capacity maxMaskedLetters = do
  theCache <- Cache.mkCache capacity
  return $ DictionaryCache dictionaryDirectory maxMaskedLetters theCache

-- Look up a dictionary by language code.
lookup :: String -> DictionaryCache -> IOExceptT String WordDictionary
lookup languageCode (dictionaryCache @ DictionaryCache {dictionaryDirectory, cache}) = do
  let code = if null languageCode then Dict.defaultLanguageCode else languageCode
  Cache.lookup code cache `catchError` (\_ -> readDictionaryFile dictionaryCache code)

-- Get the dictionary for the default language (defined in WordDictionary).
lookupDefault :: DictionaryCache -> IOExceptT String WordDictionary
lookupDefault = lookup Dict.defaultLanguageCode

-- Private functions.

readDictionaryFile :: DictionaryCache -> String -> IOExceptT String WordDictionary
readDictionaryFile DictionaryCache {dictionaryDirectory, maxMaskedLetters, cache} languageCode = do
  path <- liftIO $ mkDictionaryPath dictionaryDirectory languageCode
  lines <- ExceptT $ catchAny (readDictionaryInternal path) showException
  let words = (Char.toUpper <$>) <$> lines
      dictionary = Dict.mkDictionary languageCode words maxMaskedLetters
  Cache.insert languageCode dictionary cache
  return dictionary

readDictionaryInternal :: String -> IOEither String [String]
readDictionaryInternal path = do
  -- print $ "reading file: " ++ path
  contents <- readFile path
  return $ Right $ lines contents

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

showException :: SomeException -> IOEither String [String]
showException someExc = return $ Left $ show someExc


