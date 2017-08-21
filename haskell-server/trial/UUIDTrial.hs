--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import Data.UUID
import Data.UUID.V4

main :: IO ()

main = do
  uuid <- nextRandom
  print $ toString uuid


