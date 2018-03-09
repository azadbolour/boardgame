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
import qualified Data.Set as Set

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
import Bolour.Language.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified Bolour.Language.Util.WordUtil as WordUtil
import qualified Bolour.Language.Domain.WordDictionary as Dict

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

testBoard = Board.mkBoardFromPieces baseTestGrid 6
-- gridRows = Board.rowsAsStrings testBoard

blankChar = WordUtil.blankChar

trayCapacity :: Int
trayCapacity = 5

trayCapacity1 = 7

maxMaskedWords :: Int
maxMaskedWords = 2
myWords :: [String]
myWords = ["FAN", "PICK", "PACKER", "SCREEN", "POTENT"]
maskedWords = Set.toList $ Dict.mkMaskedWords myWords maxMaskedWords
dictionary = Dict.mkDictionary "en" myWords maskedWords maxMaskedWords

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
      let content = ['A', 'B', blankChar, blankChar, 'N', 'D']
          word = "ABOUND"
      Matcher.wordFitsContent content word `shouldBe` True
    it "non-matching word" $ do
      let content = ['A', blankChar, 'E']
          word = "ARK"
      Matcher.wordFitsContent content word `shouldBe` False

  describe "find optimal match" $ do
    it "find optimal match" $ do
      let trayContents = "PCKER"
          optimal = Maybe.fromJust $ Matcher.findOptimalMatch dictionary testBoard trayContents
      snd optimal `shouldBe` "PACKER"

  describe "make strip point" $ do
    it "X strip has correct strip point" $ do
      let lineNumber = 1
          col = 1
          size = 3
          strip = Board.stripOfBoard testBoard Axis.X lineNumber col size
          offset = 2
          point = Strip.stripPoint strip offset
      point `shouldBe` Point lineNumber (col + offset)
    it "Y strip has correct strip point" $ do
      let lineNumber = 1
          row = 2
          size = 1
          strip = Board.stripOfBoard testBoard Axis.Y lineNumber row size
          offset = 0
          point = Strip.stripPoint strip offset
      point `shouldBe` Point (row + offset) lineNumber
