--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.SwissCheeseGridSpec where

import Data.Maybe
import Test.Hspec

import BoardGame.Common.Domain.Point (Point, Point(Point), Axis)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.SwissCheeseGrid
import qualified BoardGame.Common.Domain.SwissCheeseGrid as SwissCheeseGrid

jst = Just
baseGrid :: [[Maybe Char]]
baseGrid = [
--        0        1        2        3        4
      [Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [jst 'C', jst 'A', jst 'R', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, jst 'O', jst 'N'] -- 2
    , [jst 'E', jst 'A', jst 'R', Nothing, Nothing] -- 3
  ]

cellMaker :: Int -> Int -> Maybe Char
cellMaker row col = baseGrid !! row !! col

grid :: SwissCheeseGrid Char
grid = SwissCheeseGrid.mkGrid cellMaker 4 5

spec :: Spec
spec =
  describe "strips of grid" $
    it "should get strips of 4x5 grid" $ do
      let strips = SwissCheeseGrid.strips grid
      -- sequence_ $ (print . show) <$> strips
      elem (Axis.Y,4,3,1,[Nothing]) strips `shouldBe` True
      elem (Axis.X,2,2,3,[Nothing,Just 'O',Just 'N']) strips `shouldBe` True




