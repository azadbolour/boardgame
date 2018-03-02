--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.StripMatcherSpec where

import Test.Hspec

import qualified Data.Map as Map
import qualified Data.Maybe as Maybe
import qualified Data.List as List
-- import qualified Data.ByteString.Char8 as BS
-- import Data.ByteString.Char8 (ByteString)

import Bolour.Plane.Domain.Grid (Grid, Grid(Grid))
import qualified Bolour.Plane.Domain.Grid as Grid
import Bolour.Plane.Domain.Axis (Axis)
import qualified Bolour.Plane.Domain.Axis as Axis
import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import Bolour.Plane.Domain.GridValue (GridValue(GridValue))
import qualified BoardGame.Server.Domain.Board as Board
import qualified BoardGame.Server.Domain.StripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified BoardGame.Server.Domain.WordDictionary as Dict

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseTestGrid :: [[Maybe Piece]]
baseTestGrid = [
--        0        1        2        3        4        5
      [Nothing, Nothing, Nothing, pce 'C', Nothing, Nothing] -- 0
    , [Nothing, pce 'A', pce 'C', pce 'E', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'R', Nothing, Nothing] -- 2
    , [Nothing, Nothing, Nothing, pce 'T', pce 'A', pce 'X'] -- 3
    , [Nothing, Nothing, Nothing, pce 'A', Nothing, Nothing] -- 4
    , [Nothing, Nothing, Nothing, pce 'I', Nothing, Nothing] -- 5
  ]

baseTestGrid1 :: [[Maybe Piece]]
baseTestGrid1 = [
--        0        1        2        3        4        5        6
      [pce 'A', pce 'S', pce 'Q', pce 'U', pce 'A', pce 'R', pce 'E'] -- 0
    , [pce 'X', Nothing, Nothing, pce 'N', Nothing, Nothing, Nothing] -- 1
    , [pce 'T', Nothing, Nothing, pce 'M', Nothing, Nothing, pce 'M'] -- 2
    , [pce 'R', Nothing, Nothing, pce 'E', Nothing, Nothing, pce 'E'] -- 3
    , [pce 'E', pce 'H', pce 'U', pce 'S', pce 'H', pce 'E', pce 'L'] -- 4
    , [pce 'E', Nothing, Nothing, pce 'H', Nothing, Nothing, pce 'E'] -- 5
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'E'] -- 6
  ]

-- testBoard1 = Board 7 testGrid1
testBoard1 = Board.mkBoardFromPieces baseTestGrid1 7
gridRows1 = Board.rowsAsStrings testBoard1

testBoard = Board.mkBoardFromPieces baseTestGrid 6
gridRows = Board.rowsAsStrings testBoard

emptyChar = Piece.emptyChar

trayCapacity :: Int
trayCapacity = 5

trayCapacity1 = 7

stringWords :: [String]
stringWords = ["FAN", "PICK", "PACKER", "SCREEN", "POTENT"]
byteWords = stringWords
dictionary = Dict.mkDictionary "en" byteWords 2

mkCombo :: String -> String
mkCombo string = WordUtil.mkLetterCombo string

spec :: Spec
spec = do
  describe "make strips from board" $ do
    it "make strips from board" $ do
      let stripValue Strip.Strip {blanks} = blanks
          groupedStrips = Matcher.groupedPlayableStrips testBoard trayCapacity stripValue
          groupedStripsLength3 = Maybe.fromJust $ Map.lookup 3 groupedStrips
      groupedStripsLength3 `shouldSatisfy` (not . Map.null)

  describe "check word against strip" $ do
    it "matching word" $ do
      let content = ['A', 'B', emptyChar, emptyChar, 'N', 'D']
          word = "ABOUND"
      Matcher.wordFitsContent content word `shouldBe` True
    it "non-matching word" $ do
      let content = ['A', emptyChar, 'E']
          word = "ARK"
      Matcher.wordFitsContent content word `shouldBe` False

-- TODO. Needs board parameter.
--   describe "find fitting word given combinations of letters" $ do
--     it "finds fitting word" $ do
--       let blankCount = 5
--           wordLength = 6
--           groupedStrips = Matcher.groupedPlyableStrips testBoard trayCapacity
--           strips = Maybe.fromJust $ Map.lookup blankCount $ Maybe.fromJust $ Map.lookup wordLength groupedStrips
--           combos = [mkCombo "AXJQW", mkCombo "PCKER"]
--       Matcher.matchFittingCombos dictionary blankCount strips combos `shouldSatisfy` Maybe.isJust

  describe "find optimal match" $ do
    it "find optimal match" $ do
      let trayContents = "PCKER"
          optimal = Maybe.fromJust $ Matcher.findOptimalMatch dictionary testBoard trayContents
      snd optimal `shouldBe` "PACKER"

  describe "check line neighbours" $ do
    it "has X neighbors" $ do
      Board.pointIsIsolatedInLine testBoard (Point 3 2) Axis.X `shouldBe` False
      Board.pointIsIsolatedInLine testBoard (Point 3 2) Axis.X `shouldBe` False
    it "has no X neighbors" $ do
      Board.pointIsIsolatedInLine testBoard (Point 3 1) Axis.X `shouldBe` True

    it "has Y neighbors" $ do
      Board.pointIsIsolatedInLine testBoard (Point 4 5) Axis.Y `shouldBe` False
    it "has no Y neighbors" $ do
      Board.pointIsIsolatedInLine testBoard (Point 0 5) Axis.Y `shouldBe` True
      Board.pointIsIsolatedInLine testBoard (Point 3 2) Axis.Y `shouldBe` True

  describe "make strip point" $ do
    it "X strip has correct strip point" $ do
      let lineNumber = 1
          col = 1
          size = 3
          strip = Strip.lineStrip Axis.X lineNumber (gridRows !! lineNumber) col size
          offset = 2
          point = Strip.stripPoint strip offset
      point `shouldBe` Point lineNumber (col + offset)
    it "Y strip has correct strip point" $ do
      let lineNumber = 1
          row = 2
          size = 1
          strip = Strip.lineStrip Axis.Y lineNumber (List.transpose gridRows !! lineNumber) row size
          offset = 0
          point = Strip.stripPoint strip offset
      point `shouldBe` Point (row + offset) lineNumber
