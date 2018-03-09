--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Language.Domain.DictionaryIO (
    readDictionary
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

-- dictionaryFileName :: String -> String
-- dictionaryFileName languageCode = languageCode ++ dictionaryFileSuffix
--
-- maskedWordsFileName :: String -> String
-- maskedWordsFileName languageCode = languageCode ++ maskedWordsFileSuffix

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
  dictionary <- readDictionary languageCode dictionaryDir maxMaskedLetters
  DictCache.insert languageCode dictionary dictionaryCache

readDictionary :: String -> String -> Int -> IOExceptT String WordDictionary
readDictionary languageCode dictionaryDir maxMaskedLetters = do
  words <- readWordsFile dictionaryDir languageCode dictionaryFileSuffix
  maskedWords <- readWordsFile dictionaryDir languageCode maskedWordsFileSuffix
  let dictionary = ((Dict.mkDictionary languageCode $! words) $! maskedWords) maxMaskedLetters
  return dictionary

readWordsFile :: String -> String -> String -> IOExceptT String [String]
readWordsFile dictionaryDirectory languageCode fileSuffix = do
  let path = mkFilePath dictionaryDirectory languageCode fileSuffix
  liftIO $ print ("reading dictionary path " ++ path)
  lines <- ExceptT $ catchAny (readLines path) showException
  let words = (Char.toUpper <$>) <$> lines
  liftIO $ print ("number of lines read " ++ show (length words))
  return words

mkFilePath :: String -> String -> String -> String
mkFilePath dictionaryDir languageCode fileSuffix =
  dictionaryDir ++ "/" ++ languageCode ++ fileSuffix

readLines :: String -> IOEither String [String]
readLines path = do
  -- print $ "reading file: " ++ path
  contents <- readFile path
  return $ Right (lines $! contents)

showException :: SomeException -> IOEither String [String]
showException someExc = return $ Left $ show someExc


