--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Bolour.Util.FrequencyDistribution (
    FrequencyDistribution(..)
  , mkFrequencyDistribution
  , mkDistribution
  , randomValue
  , leastFrequentValue
  , normalizedFrequencies
  ) where

import System.Random
import Data.List
import qualified Data.Map as Map

data FrequencyDistribution value = FrequencyDistribution {
    frequencies :: [(value, Int)]
  , distribution :: [(value, Int)]
  , maxDistribution :: Int
  , frequencyMap :: Map.Map value Int
}

mkFrequencyDistribution :: Ord value => [(value, Int)] -> FrequencyDistribution value
mkFrequencyDistribution frequencies =
  let distribution = mkDistribution frequencies
      maxDistribution = snd $ last frequencies
      frequencyMap = Map.fromList frequencies
  in FrequencyDistribution frequencies distribution maxDistribution frequencyMap

mkDistribution :: [(value, Int)] -> [(value, Int)]
mkDistribution frequencies =
  let nextDistribution (val, total) (nextVal, frequency) = (nextVal, total + frequency)
  in scanl1 nextDistribution frequencies

randomValue :: FrequencyDistribution value -> IO value
randomValue FrequencyDistribution {distribution, maxDistribution} = do
  dist <- randomRIO (0, maxDistribution - 1)
  let Just index = findIndex ((<) dist . snd) distribution
      val = fst $ distribution !! index
  return val

-- | Get the least frequent value.
leastFrequentValue :: Ord value => FrequencyDistribution value -> [value] -> Maybe value
leastFrequentValue FrequencyDistribution {frequencyMap} vs =
  let freq v = Map.lookup v frequencyMap
      minFreq v1 v2 = if freq v1 <= freq v2 then v1 else v2
  in case vs of
    [] -> Nothing
    _ -> Just $ foldl1' minFreq vs

normalizedFrequencies :: Ord value => FrequencyDistribution value -> Int -> ((Map.Map value Int), Int)
normalizedFrequencies FrequencyDistribution {maxDistribution, frequencyMap} roughTotal =
  let factor :: Float = fromIntegral roughTotal / fromIntegral maxDistribution
      normalizer freq = max 1 (round $ fromIntegral freq * factor)
      normalized = normalizer <$> frequencyMap
      total = sum $ Map.elems normalized
  in (normalized, total)
