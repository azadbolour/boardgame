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
  , allStripsByLengthByBlanks
  , stripPoint
  , blankPoints
  ) where

import qualified Data.List as List
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS
import Data.Map (Map)
import qualified Data.Map as Map

import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import qualified Bolour.Util.MiscUtil as MiscUtil
import BoardGame.Common.Domain.Point (Point, Point(Point), Axis, Coordinate)
import qualified BoardGame.Common.Domain.Point as Axis
import qualified BoardGame.Common.Domain.Piece as Piece

-- | A horizontal or vertical strip of the board.
data Strip = Strip {
    axis :: Axis              -- ^ direction of the strip - X = horizontal, Y = vertical - TODO. Consistent use of axis.
  , lineNumber :: Coordinate  -- ^ position of the strip's line within all lines in teh same direction
  , begin :: Coordinate       -- ^ beginning index of the strip
  , end :: Coordinate         -- ^ ending index of the strip
  , content :: ByteString     -- ^ letters and blanks
  , letters :: LetterCombo    -- ^ existing combination of letters in the strip
  , blanks :: BlankCount      -- ^ number of blank spaces in the strip
} deriving (Eq, Show)

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

blank = Piece.noPieceValue

numBlanks :: ByteString -> Int
numBlanks string = BS.length $ BS.filter (== blank) string

nonBlankCombo :: ByteString -> LetterCombo
nonBlankCombo string =
  let nonBlanks = BS.filter (/= blank) string
  in WordUtil.mkLetterCombo nonBlanks

lineStripsForLength :: Axis -> Int -> String -> ByteCount -> [Strip]
lineStripsForLength axis lineNumber line size =
  let mkStrip from = Strip
                        axis
                        lineNumber
                        from
                        (from + size - 1)
                        content
                        (nonBlankCombo content)
                        (numBlanks content)
                          where content = BS.pack $ (take size . drop from) line
  in mkStrip <$> [0 .. length line - size]

allStripsForLengthAndAxis :: Axis -> [String] -> ByteCount -> [Strip]
allStripsForLengthAndAxis axis lines size = do
  numberedLine <- zip [0 .. length lines - 1] lines
  let mkStrip (lineNumber, line) = lineStripsForLength axis lineNumber line size
  mkStrip numberedLine

allStripsForLength :: [String] -> ByteCount -> [Strip]
allStripsForLength rows size =
  let horizontals = allStripsForLengthAndAxis Axis.X rows size
      verticals = allStripsForLengthAndAxis Axis.Y (List.transpose rows) size
  in horizontals ++ verticals

allStripsForLengthByBlanks :: [String] -> ByteCount -> Map BlankCount [Strip]
allStripsForLengthByBlanks rows size =
  let strips = allStripsForLength rows size
  in MiscUtil.mapFromValueList blanks strips

allStripsByLengthByBlanks :: [String] -> ByteCount -> Map ByteCount (Map BlankCount [Strip])
allStripsByLengthByBlanks rows maxSize =
  let byBlankMaker = allStripsForLengthByBlanks rows
      keyValueMaker size = (size, byBlankMaker size)
      keyValueList = keyValueMaker <$> [2 .. maxSize] -- word needs at least 2 letters
  in Map.fromList keyValueList

stripPoint :: Strip -> Coordinate -> Point
stripPoint (Strip {axis, lineNumber, begin}) offset =
  case axis of
  Axis.X -> Point lineNumber (begin + offset)
  Axis.Y -> Point (begin + offset) lineNumber

-- TODO. For better performance consider including blank points in Strip data structure.

blankPoints :: Strip -> [Point]
blankPoints strip @ Strip {content} =
  let indexedContent = [0 .. BS.length content] `zip` BS.unpack content
      blankIndexes = fst <$> ((Piece.charIsBlank . snd) `filter` indexedContent)
  in stripPoint strip <$> blankIndexes

