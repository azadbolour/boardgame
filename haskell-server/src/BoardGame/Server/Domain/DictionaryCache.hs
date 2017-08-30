--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.DictionaryCache (
    DictionaryCache(..)
  , mkCache
  , getDictionary
  , getDefaultDictionary
  , LinesExceptT
) where

import qualified Data.Char as Char
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS

-- import Control.Monad (join)
import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import Bolour.Util.Cache (Cache(Cache))
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict

import Paths_boardgame

type LinesExceptT = IOExceptT String [String]
type LanguageCode = String -- TODO. Move to Util.

data DictionaryCache = DictionaryCache {
    dictionaryDirectory :: String
  , cache :: Cache String IndexedLanguageDictionary
}

mkCache :: String -> Int -> IO DictionaryCache
mkCache dictionaryDirectory capacity = do
  theCache <- Cache.mkCache capacity
  return $ DictionaryCache dictionaryDirectory theCache

getDictionary :: DictionaryCache -> LanguageCode -> IOExceptT String IndexedLanguageDictionary
getDictionary (dictionaryCache @ DictionaryCache {dictionaryDirectory, cache}) languageCode = do
  let code = if null languageCode then Dict.defaultLanguageCode else languageCode
  Cache.findItem cache code `catchError` (\_ -> readDictionaryFile dictionaryCache code)

getDefaultDictionary :: DictionaryCache -> IOExceptT String IndexedLanguageDictionary
getDefaultDictionary cache = getDictionary cache Dict.defaultLanguageCode

-- TODO. Check non-existent dictionary.

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
  print $ "reading file: " ++ path
  contents <- BS.readFile path
  return $ Right $ BS.lines contents

mkDictionaryPath :: String -> String -> IO String
mkDictionaryPath dictionaryDirectory languageCode = do
  directory <- if null dictionaryDirectory
    then do
          dataDir <- getDataDir
          return $ dataDir ++ "/data"
    else return dictionaryDirectory
  let fileName = languageCode ++ "-words.txt"
  return $ directory ++ "/" ++ fileName

showException :: SomeException -> IOEither String [ByteString]
showException someExc = return $ Left $ show someExc


