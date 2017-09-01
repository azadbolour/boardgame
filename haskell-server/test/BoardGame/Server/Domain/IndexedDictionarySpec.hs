--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.IndexedDictionarySpec where

import Test.Hspec

import qualified Data.List as List
import qualified Data.ByteString.Char8 as BS
import Data.ByteString.Char8 (ByteString)

import qualified BoardGame.Server.Domain.LanguageDictionary as LangDict
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict

stringWords :: [String]
stringWords = ["GLASS", "TABLE", "SCREEN", "NO", "ON"]
byteWords = BS.pack <$> stringWords
dictionary :: Dict.IndexedLanguageDictionary
dictionary = Dict.mkDictionary "en" byteWords

spec :: Spec
spec = do
  describe "test finding word in dictionary" $ do
    it "check existing word" $ do
      LangDict.isWord dictionary (BS.pack "GLASS") `shouldBe` True
    it "check non-existent word" $ do
      LangDict.isWord dictionary (BS.pack "GLAS") `shouldBe` False
  describe "test finding word permutations" $ do
    it "find existing word permutation" $ do
      LangDict.getWordPermutations dictionary (BS.pack "ABELT") `shouldBe` [BS.pack "TABLE"]
    it "no word permutations" $ do
      LangDict.getWordPermutations dictionary (BS.pack "ABEL") `shouldBe` []
    it "2 word permutations" $ do
      (List.sort $ LangDict.getWordPermutations dictionary (BS.pack "NO")) `shouldBe` [BS.pack "NO", BS.pack "ON"]