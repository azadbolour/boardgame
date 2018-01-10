--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.Strip (
    Strip(..)
  , GroupedStrips
  , mkStrip
  , groupedStrips
  , stripPoint
  , lineStrip
  , emptyPoints
  , hasAnchor
  , pointAtOffset
  ) where

import qualified Data.List as List
import Data.ByteString.Char8 (ByteString)
-- import qualified Data.ByteString.Char8 as BS
import Data.Map (Map)
import qualified Data.Map as Map

import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified Bolour.Util.MiscUtil as MiscUtil
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.SparseGrid as SparseGrid
import BoardGame.Common.Domain.SparseGrid(SparseGrid)

-- | A horizontal or vertical strip of the board.
data Strip = Strip {
    axis :: Axis              -- ^ direction of the strip - X = horizontal, Y = vertical.
  , lineNumber :: Coordinate  -- ^ position of the strip's line within all lines in teh same direction
  , begin :: Coordinate       -- ^ beginning index of the strip
  , end :: Coordinate         -- ^ ending index of the strip
  , content :: String         -- ^ letters and blanks
  , letters :: LetterCombo    -- ^ existing combination of letters in the strip
  , blanks :: BlankCount      -- ^ number of blank spaces in the strip
} deriving (Eq, Show)

mkStrip :: Axis -> Int -> Int -> Int -> String -> Strip
mkStrip axis lineNumber begin end content =
  Strip axis lineNumber begin end content (nonBlankCombo content) (numBlanks content)

-- | Strips of a a board grouped by length and by number of blanks.
--   They are grouped by length to allow longer strips to be matched first (they are of highest value).
--   They are grouped by the number of blanks so that a given combination of tray letters can be tested
--   only against those strips that have the right number of blanks (= the size of the combination).
type GroupedStrips = Map ByteCount (Map BlankCount [Strip])

-- | Does a given word fit exactly in a strip.
--   The word have have been chosen to have the combination of the strip's letters
--   and a combination of tray letters equal in size to the strip's blanks.
--   The word would have been some permutation of the combined strip and tray letters.
--   That permutation may or may not match the strips existing letters.
matchWordToStrip :: Strip -> DictWord -> Maybe (Strip, DictWord)

matchWordToStrip strip word = Nothing

-- | Get one matching word to the strip among the given words.
--   All the words being tested would have had the same length.
--   So they would all have the same score and any one will do.
matchWordsToStrip :: Strip -> [DictWord] -> Maybe (Strip, DictWord)

matchWordsToStrip strip words = Nothing

emptyChar = Piece.emptyChar

numBlanks :: String -> Int
numBlanks string = length $ filter (== emptyChar) string

nonBlankCombo :: String -> LetterCombo
nonBlankCombo string =
  let nonBlanks = filter (/= emptyChar) string
  in WordUtil.mkLetterCombo nonBlanks

lineStrip :: Axis -> Coordinate -> String -> Int -> ByteCount -> Strip
lineStrip axis lineNumber line offset size =
  mkStrip axis lineNumber offset (offset + size - 1) stringContent
    where stringContent = (take size . drop offset) line

stripPoint :: Strip -> Coordinate -> Point
stripPoint (Strip {axis, lineNumber, begin}) offset =
  case axis of
  Axis.X -> Point lineNumber (begin + offset)
  Axis.Y -> Point (begin + offset) lineNumber

-- TODO. For better performance consider including emptyChar points in Strip data structure.

emptyPoints :: Strip -> [Point]
emptyPoints strip @ Strip {content} =
  let indexedContent = [0 .. length content] `zip` content
      emptyIndexes = fst <$> ((Piece.isEmptyChar . snd) `filter` indexedContent)
  in stripPoint strip <$> emptyIndexes

hasAnchor :: Strip -> Bool
hasAnchor strip @ Strip { letters } = length letters > 0

-- TODO. Use Point colinearPoint.
pointAtOffset :: Strip -> Int -> Point
pointAtOffset (Strip {lineNumber, begin, axis}) offset =
  case axis of
    Axis.X -> Point lineNumber (begin + offset)
    Axis.Y -> Point (begin + offset) lineNumber

-- type GroupedStrips = Map ByteCount (Map BlankCount [Strip])

stripLength :: Strip -> Int
stripLength Strip {begin, end} = end - begin + 1

groupedStrips :: SparseGrid Piece -> GroupedStrips
groupedStrips grid =
  let gridStrips = SparseGrid.lineSegments grid
      strips = gridStripToStrip <$> gridStrips
      mapByLength = MiscUtil.mapFromValueList stripLength strips
      blankMapMaker = MiscUtil.mapFromValueList blanks
  in blankMapMaker <$> mapByLength

gridStripToStrip :: (Axis, Coordinate, Coordinate, Int, [Maybe Piece]) -> Strip
gridStripToStrip (axis, lineNumber, offset, size, maybeCharList) =
  mkStrip axis lineNumber offset (offset + size - 1) content
    where content = (Piece.value . Piece.fromMaybe) <$> maybeCharList

