--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.SpecUtil (
    satisfiesRight
  , satisfiesLeft
  , satisfiesJust
  ) where

import Data.Maybe
import Data.Either
import Test.Hspec

satisfiesRight :: (Show a, Show b) => Either a b -> IO b
satisfiesRight value = do
  value `shouldSatisfy` isRight
  let (Right good) = value
  return good

satisfiesLeft :: (Show a, Show b) => Either a b -> IO a
satisfiesLeft value = do
  value `shouldSatisfy` isLeft
  let (Left err) = value
  return err

satisfiesJust :: (Show a) => Maybe a -> IO a
satisfiesJust value = do
  value `shouldSatisfy` isJust
  let (Just good) = value
  return good



