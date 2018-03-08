
module BoardGame.Server.Domain.HopelessBlanksSpec2 where

import Test.Hspec

import qualified Data.Either as Either
import Control.Monad.Except (runExceptT)

import Bolour.Language.Domain.WordDictionary (
    WordDictionary
  , WordDictionary(WordDictionary)
  )
import qualified Bolour.Language.Domain.WordDictionary as Dict
-- import Bolour.Language.Domain.DictionaryCache (DictionaryCache)
-- import qualified Bolour.Language.Domain.DictionaryCache as Cache

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
import Bolour.Language.Domain.DictionaryIO (readDictionaryFile)


trayCapacity :: Int
trayCapacity = 7
dimension :: Int
dimension = 7

pce :: Char -> Maybe Piece
pce s = Just $ Piece s "" -- Ignore id.

baseGrid :: [[Maybe Piece]]
baseGrid = [
--        0        1        2        3        4        5        6
      [Nothing, pce 'T', Nothing, Nothing, Nothing, Nothing, Nothing] -- 0
    , [pce 'T', pce 'O', pce 'R', Nothing, Nothing, Nothing, Nothing] -- 1
    , [pce 'O', pce 'R', Nothing, pce 'O', pce 'N', Nothing, Nothing] -- 2
    , [pce 'W', pce 'I', pce 'D', pce 'O', pce 'W', Nothing, Nothing] -- 3
    , [Nothing, pce 'C', Nothing, Nothing, Nothing, Nothing, Nothing] -- 4
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 5
    , [Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing] -- 6
  ]

board = Board.mkBoardFromPieces baseGrid 7

-- TODO. Add assertions.

spec :: Spec
spec = do
  dictionary <- runIO getDictionary
  describe "hopeless point detection" $ do
    it "should find hopeless blank points" $ do
      let hopeless = StripMatcher.hopelessBlankPoints board dictionary trayCapacity
      print hopeless
      let hopelessX = StripMatcher.hopelessBlankPointsForAxis board dictionary trayCapacity Axis.X
      print hopelessX
      let hopelessY = StripMatcher.hopelessBlankPointsForAxis board dictionary trayCapacity Axis.Y
      print hopelessY
    it "should find hopeless blank point recursively" $ do
      let (board', hopelessPoints) = StripMatcher.setHopelessBlankPointsAsDeadRecursive board dictionary trayCapacity
      print hopelessPoints


getDictionary :: IO WordDictionary
getDictionary = do
  Right dictionary <- runExceptT $ readDictionaryFile "" "data" 2
  return dictionary

-- getDictionary :: IO WordDictionary
-- getDictionary = do
--   cache <- Cache.mkCache "data" 20 2
--   eitherDictionary <- runExceptT $ Cache.lookup "" cache
--   return $ head $ Either.rights [eitherDictionary]
--



