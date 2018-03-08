--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Language.Domain.DictionaryIO (
    readDictionaryFile
  , readAllDictionaries
) where

import Prelude hiding (lookup)
import qualified Data.Char as Char

import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Control.Monad.IO.Class (liftIO)
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)
import Bolour.Language.Domain.WordDictionary (WordDictionary)
import qualified Bolour.Language.Domain.WordDictionary as Dict
import Bolour.Language.Domain.DictionaryCache (DictionaryCache)
import qualified Bolour.Language.Domain.DictionaryCache as DictCache

dictionaryFileSuffix = "-words.txt"
maskedWordsFileSuffix = "-masked-words.txt"

dictionaryFileName :: String -> String
dictionaryFileName languageCode = languageCode ++ dictionaryFileSuffix

maskedWordsFileName :: String -> String
maskedWordsFileName languageCode = languageCode ++ maskedWordsFileSuffix

-- TODO. Use specific exceptions for the language module.
readAllDictionaries :: String -> [String] -> Int -> Int -> IOExceptT String DictionaryCache
readAllDictionaries dictionaryDir languageCodes maxDictionaries maxMaskedLetters = do
  dictionaryCache <- liftIO $ DictCache.mkCache maxDictionaries
  readAndSaveDictionaries dictionaryDir dictionaryCache languageCodes maxMaskedLetters
  return dictionaryCache

readAndSaveDictionaries :: String -> DictionaryCache -> [String] -> Int -> IOExceptT String [()]
readAndSaveDictionaries dictionaryDir dictionaryCache languageCodes maxMaskedLetters =
  let dictMaker languageCode = readAndSaveDictionary languageCode dictionaryDir dictionaryCache maxMaskedLetters
  in mapM dictMaker languageCodes

readAndSaveDictionary :: String -> String -> DictionaryCache -> Int -> IOExceptT String ()
readAndSaveDictionary languageCode dictionaryDir dictionaryCache maxMaskedLetters = do
  dictionary <- readDictionaryFile languageCode dictionaryDir maxMaskedLetters
  DictCache.insert languageCode dictionary dictionaryCache

readDictionaryFile :: String -> String -> Int -> IOExceptT String WordDictionary
readDictionaryFile languageCode dictionaryDirectory maxMaskedLetters = do
  let path = mkDictionaryPath dictionaryDirectory languageCode
  lines <- ExceptT $ catchAny (readDictionaryInternal path) showException
  let words = (Char.toUpper <$>) <$> lines
      dictionary = Dict.mkDictionary languageCode words maxMaskedLetters
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


