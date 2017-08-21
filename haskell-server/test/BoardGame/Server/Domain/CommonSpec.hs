--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.CommonSpec where

import Test.Hspec
import BoardGame.Common.Domain.Point (Point, Point(Point))
import qualified BoardGame.Common.Domain.Point as Point

spec :: Spec
spec = do
  describe "Grid Point" $ do
    it "has expected x and y coordinates" $ do
       let point = Point 5 5
       let Point.Point {row, col} = point
       row `shouldSatisfy` (== 5)
       col `shouldSatisfy` (== 5)

