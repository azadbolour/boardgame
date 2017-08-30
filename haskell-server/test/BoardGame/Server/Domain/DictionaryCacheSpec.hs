--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.DictionaryCacheSpec where

import Test.Hspec

import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS
import qualified Data.Either as Either
import Control.Monad.Except (runExceptT)

import BoardGame.Server.Domain.IndexedLanguageDictionary (
    IndexedLanguageDictionary
  , IndexedLanguageDictionary(IndexedLanguageDictionary)
  )
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import BoardGame.Server.Domain.DictionaryCache (DictionaryCache, DictionaryCache(DictionaryCache))
import qualified BoardGame.Server.Domain.DictionaryCache as Cache

spec :: Spec
spec = do
  describe "test reading dictionary" $
    it "read english dictionary" $ do
      cache <- Cache.mkCache "" 20
      eitherDictionary <- runExceptT $ Cache.getDictionary cache ""
      let dictionary = head $ Either.rights [eitherDictionary]
      Dict.isWord dictionary (BS.pack "TEST") `shouldBe` True



