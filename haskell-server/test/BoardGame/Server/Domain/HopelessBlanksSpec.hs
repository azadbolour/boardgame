module BoardGame.Server.Domain.HopelessBlanksSpec where

import Test.Hspec

import qualified Data.Set as Set

import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.StripMatcher as StripMatcher
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board, Board(Board))
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import Bolour.Plane.Domain.GridValue (GridValue, GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece
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

gridPieces :: [GridPiece]
gridPieces = [
    GridValue (Piece 'A' "0") (Point 2 0),
    GridValue (Piece 'N' "1") (Point 2 1),
    GridValue (Piece 'D' "2") (Point 2 2),
    GridValue (Piece 'T' "3") (Point 0 1),
    GridValue (Piece 'A' "4") (Point 1 1)
  ]

board = Board.setPiecePoints emptyBoard gridPieces

spec :: Spec
spec = do
  describe "hopeless blanks" $
    it "find hopeless blanks" $ do
      let hopeless = StripMatcher.hopelessBlankPoints board dictionary trayCapacity
      print hopeless
      let hopelessX = StripMatcher.hopelessBlankPointsForAxis board dictionary trayCapacity Axis.X
      print hopelessX
      let hopelessY = StripMatcher.hopelessBlankPointsForAxis board dictionary trayCapacity Axis.Y
      print hopelessY
      -- Dict.isWord dictionary "TEST" `shouldBe` True
  describe "masked words" $
    it "compute masked words" $ do
      Dict.isMaskedWord dictionary " A " `shouldBe` True
      Dict.isMaskedWord dictionary "  D" `shouldBe` True
  describe "set hopeless blank points as dead recursive" $
    it "set hopeless blank points as dead recursive" $ do
      let (finalBoard, deadPoints) = StripMatcher.setHopelessBlankPointsAsDeadRecursive board dictionary trayCapacity
      print deadPoints

