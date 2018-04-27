--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}

module Bolour.Util.FrequencyDistributionSpec where

import Test.Hspec
import qualified Data.Map as Map
import Data.List
import Bolour.Util.FrequencyDistribution

spec :: Spec
spec =
  describe "calculate distributions" $ do
    it "calculate" $ do
      let freqs = [('A', 100), ('B', 25)]
          frequencyDistribution = mkFrequencyDistribution freqs
          FrequencyDistribution {distribution, maxDistribution} = frequencyDistribution
      distribution `shouldBe` [('A', 100), ('B', 125)]
    it "gets random values" $ do
      let freqs = [('A', 0), ('B', 1), ('C', 1)]
          frequencyDistribution = mkFrequencyDistribution freqs
          list = replicate 20 frequencyDistribution
      values <- sequence $ randomValue <$> list
      let maybeA = find (== 'A') values
      maybeA `shouldBe` Nothing
      let bs = filter (== 'B') values
      let cs = filter (== 'C') values
      (length bs + length cs) `shouldBe` 20
      print $ "B: " ++ show (length bs)
      print $ "C: " ++ show (length cs)
