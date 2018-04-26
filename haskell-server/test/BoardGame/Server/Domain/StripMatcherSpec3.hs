--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.StripMatcherSpec3 where

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
--        0        1        2        3
      [Nothing, Nothing, Nothing] -- 0
    , [pce 'P', pce 'A', Nothing] -- 1
    , [Nothing, Nothing, Nothing] -- 2
  ]

testBoard = Board.mkBoardFromPieces baseTestGrid 3

trayCapacity :: Int
trayCapacity = 1

maxMaskedWords :: Int
maxMaskedWords = 2

stringWords :: [String]
stringWords = ["AS"]
maskedWords = Set.toList $ Dict.mkMaskedWords stringWords maxMaskedWords
dictionary = Dict.mkDictionary "en" stringWords maskedWords maxMaskedWords
trayContents = "S"

spec :: Spec
spec =
  describe "find optimal match" $
    it "optimal match checks cross words" $ do
      let optimal = Matcher.findOptimalMatch dictionary testBoard trayContents
      print optimal
      snd (Maybe.fromJust optimal) `shouldBe` "AS"