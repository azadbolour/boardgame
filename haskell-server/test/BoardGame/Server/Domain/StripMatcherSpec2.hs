--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.StripMatcherSpec2 where

import Test.Hspec

import qualified Data.Map as Map
import qualified Data.Maybe as Maybe
import qualified Data.List as List
import qualified Data.Set as Set

import Bolour.Plane.Domain.Grid (Grid, Grid(Grid))
import qualified Bolour.Plane.Domain.Grid as Grid
import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import qualified Bolour.Plane.Domain.Axis as Axis
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import Bolour.Plane.Domain.GridValue (GridValue(GridValue))
import qualified BoardGame.Server.Domain.Board as Board
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import BoardGame.Server.Domain.Strip (Strip(Strip))
import qualified BoardGame.Server.Domain.StripMatcher as Matcher
import qualified BoardGame.Server.Domain.Strip as Strip
import Bolour.Language.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified Bolour.Language.Util.WordUtil as WordUtil
import qualified Bolour.Language.Domain.WordDictionary as Dict

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseTestGrid :: [[Maybe Piece]]
baseTestGrid = [
--        0        1        2        3        4        5        6        7        8        9
      [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'O', Nothing, Nothing, Nothing] -- 0
    , [Nothing, Nothing, Nothing, Nothing, pce 'J', pce 'U', pce 'N', pce 'T', pce 'A', Nothing] -- 1
    , [Nothing, Nothing, Nothing, Nothing, pce 'E', Nothing, pce 'E', Nothing, Nothing, Nothing] -- 2
    , [Nothing, Nothing, Nothing, Nothing, pce 'T', Nothing, pce 'I', Nothing, Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'R', pce 'O', pce 'E', Nothing] -- 4
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'I', Nothing, Nothing, Nothing] -- 5
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, pce 'C', Nothing, Nothing, Nothing] -- 6
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 7
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 8
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 9
  ]

testBoard = Board.mkBoardFromPieces baseTestGrid 9

trayCapacity :: Int
trayCapacity = 7

maxMaskedWords :: Int
maxMaskedWords = 2

stringWords :: [String]
stringWords = ["WIDENERS", "UN", "AS"]
maskedWords = Set.toList $ Dict.mkMaskedWords stringWords maxMaskedWords
dictionary = Dict.mkDictionary "en" stringWords maskedWords maxMaskedWords
trayContents = "WIDNRS"

spec :: Spec
spec =
  describe "find optimal match" $ do
    it "optimal match checks cross words" $ do
      let optimal = Matcher.findOptimalMatch dictionary testBoard trayContents
      print optimal
      snd (Maybe.fromJust optimal) `shouldBe` "AS"
    it "no fitting word" $ do
      let combo = "DINRSW"
          blanks = 6
          strip = Strip Axis.X 2 1 8 [' ', ' ', ' ', 'E', ' ', 'E', ' ', ' '] "EE" blanks
          crossWords = CrossWordFinder.findStripCrossWords testBoard strip "WIDENERS"
          maybeWords = Matcher.findFittingWord testBoard dictionary blanks strip [combo]
      print crossWords
      print maybeWords
      maybeWords `shouldBe` Nothing