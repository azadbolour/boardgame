--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.WordMatcherSpec where

-- import Data.List
import Data.Maybe
-- import Data.List (transpose)
import Test.Hspec

import BoardGame.Server.Domain.Grid (Grid, Grid(Grid))
import qualified BoardGame.Server.Domain.Grid as Grid
import BoardGame.Common.Domain.Point (Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
-- import qualified BoardGame.Common.Domain.GridValue as GridValue
-- import qualified BoardGame.Common.Domain.GridPiece as GridPiece
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Server.Domain.Tray (Tray(Tray))
-- import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.Board (Board(Board))
import qualified BoardGame.Server.Domain.Play as Play
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.BoardStripMatcher
import qualified BoardGame.Server.Domain.BoardStripMatcher as BoardStripMatcher
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseTestGrid :: Grid (Maybe Piece)
baseTestGrid = Grid [
--        0        1        2        3        4        5        6        7        8
      [Nothing, Nothing, Nothing, pce 'C', Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [Nothing, pce 'A', pce 'C', pce 'E', Nothing, Nothing, Nothing, Nothing, Nothing] -- 1
    , [Nothing, Nothing, Nothing, pce 'R', Nothing, Nothing, Nothing, Nothing, Nothing] -- 2
    , [Nothing, Nothing, Nothing, pce 'T', pce 'A', pce 'X', Nothing, Nothing, Nothing] -- 3
    , [Nothing, Nothing, Nothing, pce 'A', Nothing, Nothing, Nothing, Nothing, Nothing] -- 4
    , [Nothing, Nothing, Nothing, pce 'I', Nothing, Nothing, Nothing, Nothing, Nothing] -- 5
    , [Nothing, Nothing, Nothing, pce 'N', Nothing, Nothing, Nothing, Nothing, Nothing] -- 6
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 7
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 8
  ]

testGrid :: Grid GridPiece
testGrid =
  let cellMaker r c = fromMaybe Piece.noPiece (Grid.getValue baseTestGrid r c)
  in Grid.mkPointedGrid cellMaker 9 9

testBoard = Board 9 9 testGrid

testTrayPieces = [Piece 'T' "000", Piece 'D' "100", Piece 'B' "200", Piece 'O' "400", Piece 'X' "500", Piece 'E' "600"]
testTray = Tray (length testTrayPieces) testTrayPieces

word = "BOLD"
strip0 = [
      GridValue Piece.noPiece (Point 0 1)
    , GridValue (Piece 'O' "1") (Point 0 2)
    , GridValue (Piece 'L' "2") (Point 0 3)
    , GridValue Piece.noPiece (Point 0 4)
  ]

strip1 = [
      GridValue Piece.noPiece (Point 0 1)
    , GridValue (Piece 'O' "1") (Point 0 2)
    , GridValue (Piece 'L' "2") (Point 0 3)
    , GridValue Piece.noPiece (Point 0 4)
  ]

vacantStrip = [
      GridValue Piece.noPiece (Point 0 1)
    , GridValue Piece.noPiece (Point 0 2)
  ]

fullStrip = [
      GridValue (Piece 'O' "1") (Point 0 1)
    , GridValue (Piece 'L' "2") (Point 0 2)
  ]

spec :: Spec
spec = do
  describe "strip properties" $ do
    it "strip is vacant" $ do
        BoardStripMatcher.stripIsVacant strip0 `shouldBe` False
        BoardStripMatcher.stripIsVacant vacantStrip `shouldBe` True
        BoardStripMatcher.stripIsVacant fullStrip `shouldBe` False
    it "strip is full" $ do
        BoardStripMatcher.stripIsFull strip0 `shouldBe` False
        BoardStripMatcher.stripIsFull vacantStrip `shouldBe` False
        BoardStripMatcher.stripIsFull fullStrip `shouldBe` True
  describe "match word to strip" $
    it "simple strip match" $ do
        let trayPieces = [Piece 'B' "100", Piece 'C' "200", Piece 'D' "400"]
        let maybeMatch = wordMatcher word strip0 trayPieces
        maybeMatch `shouldSatisfy` isJust
        let Just (playPieces, remainingPieces) = maybeMatch
        length playPieces `shouldBe` 4
        length remainingPieces `shouldBe` 1
        Piece.value (head remainingPieces) `shouldBe` 'C'
        let word' = PlayPiece.playPiecesToWord playPieces
        word' `shouldBe` word
  describe "no match to strip and tray" $ do
    it "no match from tray" $ do
       let trayPieces = [Piece 'C' "200", Piece 'D' "400"]
       let maybeMatch = wordMatcher word strip0 trayPieces
       maybeMatch `shouldBe` Nothing
    it "no match from strip" $ do
       let trayPieces = [Piece 'B' "100", Piece 'C' "200", Piece 'D' "400"]
       let maybeMatch = wordMatcher "BALD" strip0 trayPieces
       maybeMatch `shouldBe` Nothing
  describe "match word to strips" $
    it "matches strips of same length" $ do
       let trayPieces = [Piece 'B' "100", Piece 'C' "200", Piece 'D' "400"]
       let strips = [strip0, strip1]
       let matches = matchWordToStripsOfSameLength word strips trayPieces
       length matches `shouldBe` 2
       let (play, remainingTray) = head matches
       let word' = Play.playToWord play
       word' `shouldBe` word
  describe "no match to strips" $ do
    it "no match from tray" $ do
       let trayPieces = [Piece 'C' "200", Piece 'D' "400"]
       let strips = [strip0, strip1]
       let matches = matchWordToStripsOfSameLength word strips trayPieces
       matches `shouldBe` []
    it "no match from strip" $ do
       let trayPieces = [Piece 'B' "100", Piece 'C' "200", Piece 'D' "400"]
       let strips = [strip0, strip1]
       let matches = matchWordToStripsOfSameLength "BALD" strips trayPieces
       matches `shouldBe` []
  describe "find matches on board" $ do
    it "finds matches on test board" $ do
       let words = ["NOMATCH2", "TAB", "BIT", "NOMATCH1"]
           matches = findMatchesOnBoard words testBoard testTray
       sequence_ $ (print . shortPlayPieces) <$> (Play.playPieces <$> matches)
       print $ length matches
       print $ Play.playToWord <$> matches
       length matches `shouldSatisfy` ((<) 1)

shortPlayPiece :: PlayPiece -> (Char, Int, Int, Bool)
shortPlayPiece pp =
  let PlayPiece.PlayPiece {piece, point, moved} = pp
      Point.Point {row, col} = point
  in (
    Piece.value $ piece
  , Point.row point
  , Point.col point
  , PlayPiece.moved pp
 )

shortPlayPieces :: [PlayPiece] -> [(Char, Int, Int, Bool)]
shortPlayPieces pps = shortPlayPiece <$> pps