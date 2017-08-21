--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import Control.Monad
import Data.Map as Map

import qualified BoardGame.Common.Domain.Piece as Piece

accumulate :: Map Char Int -> Char -> Map Char Int
accumulate map value =
  let count = Map.lookup value map
  in case count of
     Nothing -> insert value 1 map
     Just cnt -> insert value (cnt + 1) map

addLetter :: Map Char Int -> IO (Map Char Int)
addLetter map = do
  letter <- Piece.randomLetter
  let map' = accumulate map letter
  return map'

main :: IO ()

main = do
  resultMap <- foldM (\map i -> addLetter map) empty [1 .. 10000]
  print resultMap

