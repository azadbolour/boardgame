{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module Bolour.Plane.Domain.BlackWhiteGridSpec where

import Test.Hspec

import Bolour.Util.BlackWhite
import qualified Bolour.Plane.Domain.BlackWhitePoint as BlackWhitePoint
import Bolour.Plane.Domain.BlackWhitePoint (BlackWhitePoint, BlackWhitePoint(BlackWhitePoint))
import Bolour.Plane.Domain.BlackWhiteGrid (BlackWhiteGrid)
import qualified Bolour.Plane.Domain.BlackWhiteGrid as G
import Bolour.Plane.Domain.Axis (Height, Width)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Axis as Axis

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
    , [black,         black,          black,         black,         justWhite 'A']
    , [justWhite 'A', justWhite 'B',  justWhite 'C', justWhite 'D', justWhite 'E']
    , [justWhite 'A', justWhite 'B',  emptyWhite,    justWhite 'D', emptyWhite]
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
  describe "get and set" $ do
    it "gets cells" $ do
      G.get grid (Point 2 2) `shouldBe` black
      G.get grid (Point 1 0) `shouldBe` emptyWhite
      G.get grid (Point 4 3) `shouldBe` justWhite 'D'
      G.get grid (Point 0 5) `shouldBe` black -- non-existent is black
    it "sets cells" $ do
      let grid' = G.set grid (Point 2 2) (justWhite 'X')
      G.get grid' (Point 2 2) `shouldBe` justWhite 'X'
    it "gets values" $ do
      let values = G.getValues grid
      values `shouldContain` [('A', Point 0 2), ('B', Point 0 3)]
      values `shouldContain` [('C', Point 3 2), ('D', Point 3 3), ('E', Point 3 4)]
    it "should set N values" $ do
      let bwPoints = [BlackWhitePoint emptyWhite (Point 2 0), BlackWhitePoint black (Point 0 1)]
      let grid' = G.setN grid bwPoints
      G.get grid' (Point 0 1) `shouldBe` black
  describe "next, prev, adjacent" $ do
    it "finds next" $ do
      G.next grid (Point 0 0) Axis.X `shouldBe` (Just $ BlackWhitePoint (White Nothing) (Point 0 1))
      G.next grid (Point 4 0) Axis.Y `shouldBe` Nothing
    it "finds prev" $ do
      G.prev grid (Point 2 2) Axis.X `shouldBe` (Just $ BlackWhitePoint Black (Point 2 1))
      G.prev grid (Point 0 0) Axis.Y `shouldBe` Nothing
    it "finds adjacent" $ do
      G.adjacent grid (Point 1 3) Axis.X Axis.backward `shouldBe` (Just $ BlackWhitePoint (White $ Just 'A') (Point 1 2))
      G.adjacent grid (Point 4 4) Axis.Y Axis.forward `shouldBe` Nothing
  describe "point predicates" $ do
    it "checks black, white, empty, hasValue" $ do
      Point 0 0 `shouldSatisfy` G.isBlack grid
      Point 0 1 `shouldNotSatisfy` G.isBlack grid
      Point 1 1 `shouldSatisfy` G.isEmpty grid
      Point 3 0 `shouldSatisfy` G.isWhite grid
      Point 3 0 `shouldSatisfy` G.hasValue grid
      Point 3 0 `shouldNotSatisfy` G.isEmpty grid
    it "checks in bounds" $ do
      Point 0 0 `shouldSatisfy` G.inBounds grid
      Point 5 0 `shouldNotSatisfy` G.inBounds grid
  describe "misc grid functions" $ do
    it "finds farthest neighbors" $ do
      G.farthestNeighbor grid (Point 0 1) Axis.X Axis.forward `shouldBe` Point 0 3
      G.farthestNeighbor grid (Point 2 4) Axis.X Axis.forward `shouldBe` Point 2 4 -- point is degenerate nbr
      G.farthestNeighbor grid (Point 2 4) Axis.X Axis.backward `shouldBe` Point 2 4 -- ditto
      G.farthestNeighbor grid (Point 3 3) Axis.Y Axis.forward `shouldBe` Point 4 3
      G.farthestNeighbor grid (Point 3 4) Axis.Y Axis.backward `shouldBe` Point 2 4
    it "gets dimesions" $ do
      G.numLines grid Axis.X `shouldBe` dim
      G.numLines grid Axis.Y `shouldBe` dim
    it "finds surrounding range" $ do
      G.surroundingRange grid (Point 3 0) Axis.X `shouldBe` [Point 3 0, Point 3 1, Point 3 2, Point 3 3, Point 3 4]
      G.surroundingRange grid (Point 1 2) Axis.Y `shouldBe` [Point 0 2, Point 1 2]



