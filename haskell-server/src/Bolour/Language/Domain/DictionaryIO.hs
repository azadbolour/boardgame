--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Language.Domain.DictionaryIO (
    readDictionary
  , readAllDictionaries
  , readMaskedWordsFile -- for testing
) where

import Prelude hiding (lookup)
import qualified Data.Char as Char
import qualified Data.ByteString.Lazy.Char8 as BS

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
  maskedWords <- readMaskedWordsFile dictionaryDir languageCode
  let dictionary = Dict.mkDictionary languageCode words maskedWords maxMaskedLetters
  return dictionary

-- | Use ByteStream to allow stream processing, and minimize memory overhead
--   in getting the masked words in memory. The input file is expected to
--   be in upper case.
readMaskedWordsFile :: String -> String -> IOExceptT String [BS.ByteString]
readMaskedWordsFile dictionaryDirectory languageCode = do
  let path = mkFilePath dictionaryDirectory languageCode maskedWordsFileSuffix
  liftIO $ print ("reading dictionary path " ++ path)
  theLines <- ExceptT $ catchAny (readByteStringLines path) showBSException
  liftIO $ print ("number of lines read " ++ show (length theLines))
  return theLines

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
  contents <- readFile path
  return $ Right (lines contents)

readByteStringLines :: String -> IOEither String [BS.ByteString]
readByteStringLines path = do
  contents <- BS.readFile path
  return $ Right (BS.lines contents)

showException :: SomeException -> IOEither String [String]
showException someExc = return $ Left $ show someExc

showBSException :: SomeException -> IOEither String [BS.ByteString]
showBSException someExc = return $ Left $ show someExc


