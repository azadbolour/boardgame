--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Language.Domain.DictionaryCache (
    DictionaryCache
  , mkCache
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

-- TODO. Configure [supported] languageCodes and read their dictionaries when cache is created.

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

dictionaryFileSuffix = "-words.txt"
maskedWordsFileSuffix = "-masked-words.txt"

dictionaryFileName :: String -> String
dictionaryFileName languageCode = languageCode ++ dictionaryFileSuffix

maskedWordsFileName :: String -> String
maskedWordsFileName languageCode = languageCode ++ maskedWordsFileSuffix

readDictionaryFile :: DictionaryCache -> String -> IOExceptT String WordDictionary
readDictionaryFile DictionaryCache {dictionaryDirectory, maxMaskedLetters, cache} languageCode = do
  -- path <- liftIO $ mkDictionaryPath dictionaryDirectory languageCode
  let path = mkDictionaryPath dictionaryDirectory languageCode
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

mkDictionaryPath :: String -> String -> String
mkDictionaryPath dictionaryDirectory languageCode =
  dictionaryDirectory ++ "/" ++ dictionaryFileName languageCode

showException :: SomeException -> IOEither String [String]
showException someExc = return $ Left $ show someExc


