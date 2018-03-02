--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Domain.BoardSpec where

import Test.Hspec
import Data.Either
import Bolour.Util.SpecUtil (satisfiesRight, satisfiesLeft)
import qualified Bolour.Plane.Domain.Grid as Grid
import Bolour.Plane.Domain.Point (Point, Point(Point))
import BoardGame.Server.Domain.Board (validatePoint)
import qualified BoardGame.Server.Domain.Board as Board

spec :: Spec
spec = do
  describe "Make Board" $ do
    let b = Board.mkEmptyBoard 10
    it "has edge points" $ do
       satisfiesRight $ validatePoint b $ Point 0 0
       satisfiesRight $ validatePoint b $ Point 9 0
       satisfiesRight $ validatePoint b $ Point 0 9
       satisfiesRight $ validatePoint b $ Point 9 4
       return ()
    it "does not have external points" $ do
       satisfiesLeft $ validatePoint b $ Point (-1) 0
       satisfiesLeft $ validatePoint b $ Point 10 0
       satisfiesLeft $ validatePoint b $ Point 0 10
       satisfiesLeft $ validatePoint b $ Point 9 11
       return ()

