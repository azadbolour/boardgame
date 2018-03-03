--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.WordDictionarySpec where

import Test.Hspec

import qualified Data.List as List
-- import qualified Data.ByteString.Char8 as BS
-- import Data.ByteString.Char8 (ByteString)

import Bolour.Language.Domain.WordDictionary (WordDictionary, WordDictionary(WordDictionary))
import qualified Bolour.Language.Domain.WordDictionary as Dict

stringWords :: [String]
stringWords = ["GLASS", "TABLE", "SCREEN", "NO", "ON"]
byteWords = stringWords
dictionary = Dict.mkDictionary "en" byteWords 2

spec :: Spec
spec = do
  describe "test finding word in dictionary" $ do
    it "check existing word" $ do
      Dict.isWord dictionary "GLASS" `shouldBe` True
    it "check non-existent word" $ do
      Dict.isWord dictionary "GLAS" `shouldBe` False
  describe "test finding word permutations" $ do
    it "find existing word permutation" $ do
      Dict.getWordPermutations dictionary "ABELT" `shouldBe` ["TABLE"]
    it "no word permutations" $ do
      Dict.getWordPermutations dictionary "ABEL" `shouldBe` []
    it "2 word permutations" $ do
      (List.sort $ Dict.getWordPermutations dictionary "NO") `shouldBe` ["NO", "ON"]