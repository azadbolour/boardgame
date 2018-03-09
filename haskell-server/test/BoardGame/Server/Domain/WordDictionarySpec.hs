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
import qualified Data.Set as Set

import Bolour.Language.Domain.WordDictionary (WordDictionary, WordDictionary(WordDictionary))
import qualified Bolour.Language.Domain.WordDictionary as Dict

maxMaskedWords :: Int
maxMaskedWords = 2
myWords :: [String]
myWords = ["GLASS", "TABLE", "SCREEN", "NO", "ON"]
maskedWords = Set.toList $ Dict.mkMaskedWords myWords maxMaskedWords
dictionary = Dict.mkDictionary "en" myWords maskedWords maxMaskedWords

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