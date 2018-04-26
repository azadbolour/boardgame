--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}

module Bolour.Util.FrequencyDistributionSpec where

import Test.Hspec
import Data.Map as Map
import Bolour.Util.FrequencyDistribution

spec :: Spec
spec = do
  describe "calculate distribution" $ do
    it "calculate" $ do
      let freqs = [('A', 100), ('B', 25)]
          FrequencyDistribution {distribution, maxDistribution} = mkFrequencyDistribution freqs
      distribution `shouldBe` [('A', 100), ('B', 125)]