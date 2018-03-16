--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module Bolour.Util.CompactStringSetSpec where

import Test.Hspec

import qualified Data.Map.Strict as Map
import Data.Time (UTCTime, getCurrentTime)
import Data.Time.Clock (diffUTCTime)
import Control.Concurrent (threadDelay)

import qualified Bolour.Util.CompactStringSet as Set

spec :: Spec
spec = do
  describe "compact string set" $ do
    let set = Set.mkCompactStringSet
    it "should store and retrieve strings" $ do
      let set' = Set.insert set "one"
      Set.contains set' "one" `shouldBe` True
      let set'' = Set.insertAll set' ["two", "three"]
      Set.contains set'' "two" `shouldBe` True
      Set.contains set'' "three" `shouldBe` True
      Set.contains set'' "four" `shouldBe` False

      -- Insertion of bulk data uses excessive memory. Not sure why. Give up for now.
--   describe "timing of insertions into compact string set" $ do
--     let set = Set.mkCompactStringSet
--     it "insert large lists in reasonable time" $ do
--       threadDelay (5 * 1000000)
--       begin <- getCurrentTime
--
--       contents <- readFile "dict/en-masked-words.txt"
--       let strings = lines contents
--       let s = strings !! 10000000
--       print s
--       threadDelay (5 * 1000000)
--       -- let Set.CompactStringSet { buckets } = Set.insertAll set strings
--       -- print $ "number of buckets: " ++ show (Map.size buckets)
--
--       end <- getCurrentTime
--       let diffTime = diffUTCTime end begin
--       let seconds = toInteger $ floor diffTime
--       print $ "time " ++ show seconds ++ " seconds"
--       True `shouldBe` True





