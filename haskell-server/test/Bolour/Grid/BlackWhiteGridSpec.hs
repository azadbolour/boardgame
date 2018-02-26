{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Bolour.Grid.BlackWhiteGridSpec where

import Test.Hspec

import Bolour.Util.BlackWhite
import Bolour.Grid.BlackWhiteGrid (BlackWhiteGrid, BlackWhitePoint, BlackWhitePoint(BlackWhitePoint))
import qualified Bolour.Grid.BlackWhiteGrid as G
import Bolour.Grid.Point (Point, Point(Point), Height, Width)

dim :: Int
dim = 5

justWhite :: Char -> BlackWhite Char
justWhite ch = White (Just ch)

emptyWhite :: BlackWhite Char
emptyWhite = White Nothing

black :: BlackWhite Char
black = Black

initRows = [
      [black,         emptyWhite,     justWhite 'A', justWhite 'B', emptyWhite]
    , [emptyWhite,    emptyWhite,     justWhite 'A', justWhite 'B', black]
    , [black,         black,          black,         Black,         justWhite 'A']
    , [justWhite 'A', justWhite 'B',  justWhite 'C', justWhite 'D', justWhite 'E']
    , [justWhite 'A', justWhite 'B',  emptyWhite,    justWhite 'D', justWhite 'E']
  ]

cellMaker :: Height -> Width -> BlackWhite Char
cellMaker h w = initRows !! h !! w

grid :: BlackWhiteGrid Char
grid = G.mkGrid cellMaker dim dim

spec :: Spec
spec = do
  describe "rows and cols" $ do
    let row1 = G.rows grid !! 1
    let col3 = G.cols grid !! 3
    it "row 1 cell 1" $ do
      let BlackWhitePoint {value, point} = row1 !! 1
      value `shouldBe` emptyWhite
      point `shouldBe` Point 1 1
    it "row 1 cell 4" $ do
      let BlackWhitePoint {value, point} = row1 !! 4
      value `shouldBe` black
      point `shouldBe` Point 1 4
    it "col 3 cell 0" $ do
      let BlackWhitePoint {value, point} = col3 !! 0
      value `shouldBe` justWhite 'B'
      point `shouldBe` Point 0 3



