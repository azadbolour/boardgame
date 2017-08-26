--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.DataFileSpec where

import Test.Hspec
import Bolour.Util.FileUtil

spec :: Spec
spec = do
  describe "read word list" $ do
    it "read" $ do
      words <- readDataFileAsLines "data/test-words.txt"
      length words `shouldSatisfy` (10 <)

