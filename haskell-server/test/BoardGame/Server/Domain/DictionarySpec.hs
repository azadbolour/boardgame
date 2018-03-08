--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.DictionarySpec where

import Test.Hspec

import qualified Data.Either as Either
import Control.Monad.Except (runExceptT)

import Bolour.Language.Domain.WordDictionary (
    WordDictionary
  , WordDictionary(WordDictionary)
  )
import qualified Bolour.Language.Domain.WordDictionary as Dict
import Bolour.Language.Domain.DictionaryIO (readDictionaryFile)



spec :: Spec
spec = do
  describe "test reading dictionary" $
    it "read english dictionary" $ do
      dictionary <- getDictionary
      Dict.isWord dictionary "TEST" `shouldBe` True

getDictionary :: IO WordDictionary
getDictionary = do
  Right dictionary <- runExceptT $ readDictionaryFile "en" "dict" 2
  return dictionary




