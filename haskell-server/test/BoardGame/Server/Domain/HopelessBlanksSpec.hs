--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Domain.HopelessBlanksSpec where

import Test.Hspec

import qualified Data.Set as Set

import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.StripMatcher as StripMatcher
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board, Board(Board))
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import BoardGame.Common.Domain.PiecePoint (PiecePoint, PiecePoint(PiecePoint))
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Axis as Axis

trayCapacity :: Int
trayCapacity = 3
dimension :: Int
dimension = 3

emptyBoard :: Board
emptyBoard = Board.mkEmptyBoard dimension

tray :: Tray
tray = Tray trayCapacity [] -- no need for pieces in this test

maxMaskedWords :: Int
maxMaskedWords = 2
myWords = ["AND", "TAN"]
maskedWords = Set.toList $ Dict.mkMaskedWords myWords maxMaskedWords
dictionary = Dict.mkDictionary "en" myWords maskedWords maxMaskedWords

gridPieces :: [PiecePoint]
gridPieces = [
    PiecePoint (Piece 'A' "0") (Point 2 0),
    PiecePoint (Piece 'N' "1") (Point 2 1),
    PiecePoint (Piece 'D' "2") (Point 2 2),
    PiecePoint (Piece 'T' "3") (Point 0 1),
    PiecePoint (Piece 'A' "4") (Point 1 1)
  ]

board = Board.setPiecePoints emptyBoard gridPieces

spec :: Spec
spec = do
  describe "hopeless blanks" $
    it "find hopeless blanks" $ do
      let hopeless = StripMatcher.hopelessBlankPoints board dictionary
      print hopeless
      -- Dict.isWord dictionary "TEST" `shouldBe` True
  describe "masked words" $
    it "compute masked words" $ do
      Dict.isMaskedWord dictionary " A " `shouldBe` True
      Dict.isMaskedWord dictionary "  D" `shouldBe` True
  describe "set hopeless blank points as dead recursive" $
    it "set hopeless blank points as dead recursive" $ do
      let (finalBoard, deadPoints) = StripMatcher.findAndSetBoardBlackPoints dictionary board
      print deadPoints

