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
import qualified Data.ByteString.Char8 as BS
import Data.ByteString.Char8 (ByteString)

import BoardGame.Common.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Common.Domain.Grid as Grid
import BoardGame.Common.Domain.Point (Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import qualified BoardGame.Server.Domain.IndexedStripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseTestGrid :: Grid (Maybe Piece)
baseTestGrid = Grid [
--        0        1        2        3        4        5
      [Nothing, Nothing, Nothing, pce 'C', Nothing, Nothing] -- 0
    , [Nothing, pce 'A', pce 'C', pce 'E', Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'R', Nothing, Nothing] -- 2
    , [Nothing, Nothing, Nothing, pce 'T', pce 'A', pce 'X'] -- 3
    , [Nothing, Nothing, Nothing, pce 'A', Nothing, Nothing] -- 4
    , [Nothing, Nothing, Nothing, pce 'I', Nothing, Nothing] -- 5
  ]

baseTestGrid1 :: Grid (Maybe Piece)
baseTestGrid1 = Grid [
--        0        1        2        3        4        5        6
      [pce 'A', pce 'S', pce 'Q', pce 'U', pce 'A', pce 'R', pce 'E'] -- 0
    , [pce 'X', Nothing, Nothing, pce 'N', Nothing, Nothing, Nothing] -- 1
    , [pce 'T', Nothing, Nothing, pce 'M', Nothing, Nothing, pce 'M'] -- 2
    , [pce 'R', Nothing, Nothing, pce 'E', Nothing, Nothing, pce 'E'] -- 3
    , [pce 'E', pce 'H', pce 'U', pce 'S', pce 'H', pce 'E', pce 'L'] -- 4
    , [pce 'E', Nothing, Nothing, pce 'H', Nothing, Nothing, pce 'E'] -- 5
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'E'] -- 6
  ]

testGrid1 :: Grid GridPiece
testGrid1 =
  let cellMaker r c = Maybe.fromMaybe Piece.emptyPiece (Grid.getValue baseTestGrid1 r c)
  in Grid.mkPointedGrid cellMaker 7 7

testBoard1 = Board 7 testGrid1
gridRows1 = Board.charRows testBoard1

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = Maybe.fromMaybe Piece.emptyPiece (Grid.getValue baseTestGrid r c)
  in Grid.mkPointedGrid cellMaker 6 6

testBoard = Board 6 testGrid
gridRows = Board.charRows testBoard

emptyChar = Piece.emptyChar

trayCapacity :: Int
trayCapacity = 5

trayCapacity1 = 7

stringWords :: [String]
stringWords = ["FAN", "PICK", "PACKER", "SCREEN", "POTENT"]
byteWords = BS.pack <$> stringWords
dictionary = Dict.mkDictionary "en" byteWords

mkCombo :: String -> ByteString
mkCombo string = WordUtil.mkLetterCombo $ BS.pack string

spec :: Spec
spec = do
  describe "make strips from board" $ do
    it "make strips from board" $ do
      let groupedStrips = Matcher.computePlayableStrips testBoard trayCapacity
          groupedStripsLength3 = Maybe.fromJust $ Map.lookup 3 groupedStrips
      groupedStripsLength3 `shouldSatisfy` (not . Map.null)

  describe "check word against strip" $ do
    it "matching word" $ do
      let content = BS.pack ['A', 'B', emptyChar, emptyChar, 'N', 'D']
          word = BS.pack "ABOUND"
      Matcher.wordFitsContent content word `shouldBe` True
    it "non-matching word" $ do
      let content = BS.pack ['A', emptyChar, 'E']
          word = BS.pack "ARK"
      Matcher.wordFitsContent content word `shouldBe` False

  describe "find fitting word given combinations of letters" $ do
    it "finds fitting word" $ do
      let blankCount = 5
          wordLength = 6
          groupedStrips = Matcher.computePlayableStrips testBoard trayCapacity
          strips = Maybe.fromJust $ Map.lookup blankCount $ Maybe.fromJust $ Map.lookup wordLength groupedStrips
          combos = [mkCombo "AXJQW", mkCombo "PCKER"]
      Matcher.matchFittingCombos dictionary blankCount strips combos `shouldSatisfy` Maybe.isJust

  describe "find optimal match" $ do
    it "find optimal match" $ do
      let trayContents = "PCKER"
          optimal = Maybe.fromJust $ Matcher.findOptimalMatch dictionary testBoard trayContents
      snd optimal `shouldBe` BS.pack "PACKER"

  describe "compute playable strips" $ do
    it "get playable strips" $ do
      let playableStrips = Matcher.computePlayableStrips testBoard1 trayCapacity1
      -- print $ (fmap . fmap) ((\s -> (Strip.content s, Strip.blankPoints s)) <$>) playableStrips
          stripsLength5Blanks4 = Maybe.fromJust $ Map.lookup 4 (Maybe.fromJust $ Map.lookup 5 playableStrips)
      mapM_ print stripsLength5Blanks4
      stripsLength5Blanks4 `shouldBe` []

    it "gets strip with empty cross-neighbors" $ do
      let lineNumber = 5
          row = 2
          size = 5
          strip = Strip.lineStrip Point.Y lineNumber (List.transpose gridRows1 !! lineNumber) row size
      print strip
      Matcher.stripBlanksAreFreeCrosswise testBoard1 strip `shouldBe` False

  describe "check line neighbours" $ do
    it "has X neighbors" $ do
      Board.pointHasNoLineNeighbors testBoard (Point 3 2) Point.X `shouldBe` False
      Board.pointHasNoLineNeighbors testBoard (Point 3 2) Point.X `shouldBe` False
    it "has no X neighbors" $ do
      Board.pointHasNoLineNeighbors testBoard (Point 3 1) Point.X `shouldBe` True

    it "has Y neighbors" $ do
      Board.pointHasNoLineNeighbors testBoard (Point 4 5) Point.Y `shouldBe` False
    it "has no Y neighbors" $ do
      Board.pointHasNoLineNeighbors testBoard (Point 0 5) Point.Y `shouldBe` True
      Board.pointHasNoLineNeighbors testBoard (Point 3 2) Point.Y `shouldBe` True

  describe "make strip point" $ do
    it "X strip has correct strip point" $ do
      let lineNumber = 1
          col = 1
          size = 3
          strip = Strip.lineStrip Point.X lineNumber (gridRows !! lineNumber) col size
          offset = 2
          point = Strip.stripPoint strip offset
      point `shouldBe` Point lineNumber (col + offset)
    it "Y strip has correct strip point" $ do
      let lineNumber = 1
          row = 2
          size = 1
          strip = Strip.lineStrip Point.Y lineNumber (List.transpose gridRows !! lineNumber) row size
          offset = 0
          point = Strip.stripPoint strip offset
      point `shouldBe` Point (row + offset) lineNumber

  describe "strip blanks are not free cross-wise" $ do
    it "not free" $ do
      let lineNumber = 2
          row = 1
          size = 4
          strip = Strip.lineStrip Point.Y lineNumber (List.transpose gridRows !! lineNumber) row size
      Matcher.stripBlanksAreFreeCrosswise testBoard strip `shouldBe` False
    it "not free" $ do
      let lineNumber = 4
          col = 3
          size = 3
          strip = Strip.lineStrip Point.X lineNumber (gridRows !! lineNumber) col size
      Matcher.stripBlanksAreFreeCrosswise testBoard strip `shouldBe` False
