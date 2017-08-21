--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

main :: IO ()

list1 :: [Either String Int]
list1 = [Right 1, Left "error1", Right 2, Left "error2"]

list2 :: [Either String Int]
list2 = [Right 1, Right 2]


main = do
  print $ sequence list1
  print $ head <$> sequence list1
  print $ sequence list2



