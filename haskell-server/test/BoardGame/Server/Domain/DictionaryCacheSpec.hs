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

import qualified Data.Either as Either
import Control.Monad.Except (runExceptT)

import Bolour.Language.Domain.WordDictionary (
    WordDictionary
  , WordDictionary(WordDictionary)
  )
import qualified Bolour.Language.Domain.WordDictionary as Dict
import Bolour.Language.Domain.DictionaryCache (DictionaryCache)
import qualified Bolour.Language.Domain.DictionaryCache as Cache

spec :: Spec
spec = do
  describe "test reading dictionary" $
    it "read english dictionary" $ do
      cache <- Cache.mkCache "data" 20 2
      eitherDictionary <- runExceptT $ Cache.lookup "" cache
      let dictionary = head $ Either.rights [eitherDictionary]
      Dict.isWord dictionary "TEST" `shouldBe` True



