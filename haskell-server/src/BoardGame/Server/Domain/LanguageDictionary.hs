--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.LanguageDictionary
  {-# DEPRECATED "use IndexedLanguageDictionary" #-} (
    LanguageDictionary(..)
  , defaultLanguageCode
  , validateWord
  , mkDummyDictionary
  , getDefaultDictionary
  , getLanguageDictionary
  ) where


import Data.Char (toUpper)
import Data.Bool (bool)

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..), runExceptT)

import Paths_boardgame

import Bolour.Util.StaticTextFileCache (TextFileCacheType)
import Bolour.Util.MiscUtil (IOExceptT)

import BoardGame.Server.Domain.GameError
import qualified Bolour.Util.StaticTextFileCache as FileCache

-- | A dictionary of words in a given language.
data LanguageDictionary = LanguageDictionary {
    languageCode :: String
  , words :: [String]
  , isDictionaryWord :: String -> Bool
}

english :: String
english = "en"

defaultLanguageCode :: String
defaultLanguageCode = english

instance Show LanguageDictionary where
  show = languageCode

{-
   Note. We can use an auxiliary field of type Set for O(log n) lookup of
   words. Or make sure the list is sorted and use your own binary search.
   [SortedList has elemOrd which is supposed to be O(log n). But its source
   looks O(n) to me.]

   These changes would requires refactoring to use a bona-fide dictionary
   cache rather than piggy-backing on the static file cache.

   For now we'll let that go, since word lookup is not the time-consuming
   part of a user interaction. Finding an optimal machine play is currently
   O(n) in the number of words (and does more work per word).

   To be revisited if it comes up in priority in profiling.
-}
getLanguageDictionary :: String -> String -> TextFileCacheType -> IOExceptT String LanguageDictionary
getLanguageDictionary dictionaryDirectory languageCode dictionaryCache = do
  let code = if null languageCode then defaultLanguageCode else languageCode
  filePath <- liftIO $ mkDictionaryPath dictionaryDirectory code
  let dictMaker words = LanguageDictionary code words (`elem` words)
      dictMapper ioEither = dictMaker <$> ioEither
  -- fileCache <- liftIO ioFileCache
  ExceptT $ dictMapper <$> runExceptT (FileCache.get dictionaryCache filePath)

getDefaultDictionary :: IO LanguageDictionary
getDefaultDictionary = do
  filePath <- mkDictionaryPath "" defaultLanguageCode
  content <- readFile filePath
  let words = lines content
      upperWords = map toUpper <$> words
  return $ LanguageDictionary defaultLanguageCode upperWords (`elem` upperWords)

mkDummyDictionary languageCode = LanguageDictionary languageCode [] (const False)

mkDictionaryPath :: String -> String -> IO String
mkDictionaryPath dictionaryDirectory languageCode = do
  directory <- if null dictionaryDirectory
    then do
          dataDir <- getDataDir
          return $ dataDir ++ "/data"
    else return dictionaryDirectory
  let fileName = languageCode ++ "-words.txt"
  return $ directory ++ "/" ++ fileName

-- TODO. Check non-existent dictionary.

-- | Word exists in the the dictionary.
validateWord :: (MonadError GameError m, MonadIO m) => LanguageDictionary -> String -> m String
validateWord languageDictionary word = do
  let valid = isDictionaryWord languageDictionary word
  bool (throwError $ InvalidWordError word) (return word) valid




