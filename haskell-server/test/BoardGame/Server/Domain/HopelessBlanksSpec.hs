module BoardGame.Server.Domain.HopelessBlanksSpec where

import Test.Hspec

import qualified BoardGame.Server.Domain.WordDictionary as Dict
import qualified BoardGame.Server.Domain.StripMatcher as StripMatcher
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Board (Board, Board(Board))
import BoardGame.Server.Domain.Tray (Tray, Tray(Tray))
import Bolour.Grid.GridValue (GridValue, GridValue(GridValue))
import BoardGame.Common.Domain.GridPiece
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import Bolour.Grid.Point (Point, Point(Point))

trayCapacity :: Int
trayCapacity = 3
dimension :: Int
dimension = 3

emptyBoard :: Board
emptyBoard = Board.mkEmptyBoard dimension

tray :: Tray
tray = Tray trayCapacity [] -- no need for pieces in this test

myWords = ["AND", "TAN"]
dictionary = Dict.mkDictionary "en" myWords 2

gridPieces :: [GridPiece]
gridPieces = [
    GridValue (Piece 'A' "0") (Point 2 0),
    GridValue (Piece 'N' "1") (Point 2 1),
    GridValue (Piece 'D' "2") (Point 2 2),
    GridValue (Piece 'T' "3") (Point 0 1),
    GridValue (Piece 'A' "4") (Point 1 1)
  ]

board = Board.setN emptyBoard gridPieces

spec :: Spec
spec = do
  describe "" $
    it "find hopeless blanks" $ do
      let hopeless = StripMatcher.hopelessBlankPoints board dictionary trayCapacity
      print hopeless
      -- Dict.isWord dictionary "TEST" `shouldBe` True
