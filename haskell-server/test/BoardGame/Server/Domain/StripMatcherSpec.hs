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
import qualified Data.ByteString.Char8 as BS
import Data.ByteString.Char8 (ByteString)

import BoardGame.Server.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Server.Domain.Grid as Grid
import BoardGame.Common.Domain.Point (Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import qualified BoardGame.Server.Domain.IndexedStripMatcher as Matcher
import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified BoardGame.Server.Domain.LanguageDictionary as Dict
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)

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

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = Maybe.fromMaybe Piece.noPiece (Grid.getValue baseTestGrid r c)
  in Grid.mkPointedGrid cellMaker 6 6

testBoard = Board 6 6 testGrid
gridRows = Board.charRows testBoard

blank = Piece.noPieceValue

trayCapacity :: Int
trayCapacity = 5

stringWords :: [String]
stringWords = ["FAN", "PICK", "PACKER", "SCREEN", "POTENT"]
byteWords = BS.pack <$> stringWords
dictionary :: IndexedLanguageDictionary
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
      let content = BS.pack ['A', 'B', blank, blank, 'N', 'D']
          word = BS.pack "ABOUND"
      Matcher.wordFitsContent content word `shouldBe` True
    it "non-matching word" $ do
      let content = BS.pack ['A', blank, 'E']
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


