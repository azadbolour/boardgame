--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Bolour.Language.Domain.WordDictionarySpec where

import Test.Hspec

import Data.List
import qualified Data.Set as Set
import Control.Monad.Except (runExceptT)

import qualified Data.ByteString.Lazy.Char8 as BS

import Bolour.Language.Domain.WordDictionary (
    WordDictionary
  , WordDictionary(WordDictionary)
  )
import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified Bolour.Language.Domain.DictionaryIO as DictIO

spec :: Spec
spec = do
  describe "reading masked words" $ do
    it "can read masked words" $ do
      Right maskedWords <- runExceptT $ DictIO.readMaskedWordsFile "data" "test"
      -- Right maskedWords <- runExceptT $ DictIO.readMaskedWordsFile "dict" "en"
      let folder acc elem = acc + 1
          number = foldl' folder 0 maskedWords
      print $ show number
      let set = Set.fromList maskedWords
      ((BS.pack "AC CUL R") `Set.member` set) `shouldBe` True

  describe "test reading dictionary" $
    it "read english dictionary" $ do
      Right dictionary <- runExceptT $ DictIO.readDictionary "test" "data" 2
      Dict.isWord dictionary "ABATEMENT" `shouldBe` True

  describe "test finding words and permutations in dictionary" $ do
    let myWords = ["GLASS", "TABLE", "SCREEN", "NO", "ON"]
        maskedWords = Set.toList $ Dict.mkMaskedWords myWords 2
        dictionary = Dict.mkDictionary "en" myWords maskedWords 2
    it "check existing word" $ do
      Dict.isWord dictionary "GLASS" `shouldBe` True
    it "check non-existent word" $ do
      Dict.isWord dictionary "GLAS" `shouldBe` False
    it "find existing word permutation" $ do
      Dict.getWordPermutations dictionary "ABELT" `shouldBe` ["TABLE"]
    it "no word permutations" $ do
      Dict.getWordPermutations dictionary "ABEL" `shouldBe` []
    it "2 word permutations" $ do
      (sort $ Dict.getWordPermutations dictionary "NO") `shouldBe` ["NO", "ON"]




