--
-- Copyright 2017-2018 Azad Bolour
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
  , stripPoint
  , stripLength
  , lineStrip
  , charLineSegmentToStrip
  , stripFromBlackWhiteLine
  , allStripsInBlackWhiteLine
  , hasAnchor
  , hasBlanks
  , pointAtOffset
  , stripsInLine
  , blankPoints
  , isDense
  , offset
  , fillBlankInStrip
  ) where

import qualified Data.List as List
import Data.ByteString.Char8 (ByteString)
import Data.Map (Map)
import qualified Data.Map as Map

import qualified Bolour.Plane.Domain.LineSegment as LineSegment
import Bolour.Plane.Domain.LineSegment (LineSegment, LineSegment(LineSegment))
import Bolour.Util.BlackWhite (BlackWhite, BlackWhite(Black, White))
import qualified Bolour.Util.BlackWhite as BlackWhite
import Bolour.Language.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified Bolour.Language.Util.WordUtil as WordUtil
import qualified Bolour.Util.MiscUtil as MiscUtil
import Bolour.Plane.Domain.Axis (Axis, Coordinate)
import Bolour.Plane.Domain.Point (Point, Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import qualified Bolour.Plane.Domain.Axis as Axis

{--
  In this module the term 'blank' means an empty slot on the board.
  Blanks, however, are not represented by the blank character ' '.
  Blanks are represented by the null character '\0'.
--}

-- | A horizontal or vertical strip of the board.
data Strip = Strip {
    axis :: Axis              -- ^ direction of the strip - X = horizontal, Y = vertical.
  , lineNumber :: Coordinate  -- ^ position of the strip's line within all lines in teh same direction
  , begin :: Coordinate       -- ^ beginning index of the strip
  , end :: Coordinate         -- ^ ending index of the strip
  , content :: String         -- ^ letters and blanks
  , letters :: LetterCombo    -- ^ existing combination of letters in the strip
  , blanks :: BlankCount      -- ^ number of blank spaces ('\0') in the strip
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

numBlanks :: String -> Int
numBlanks string = length $ filter WordUtil.isBlankChar string

nonBlankCombo :: String -> LetterCombo
nonBlankCombo string =
  let nonBlanks = filter (not . WordUtil.isBlankChar) string
  in WordUtil.mkLetterCombo nonBlanks

charLineSegmentToStrip :: LineSegment Char -> Strip
charLineSegmentToStrip LineSegment {axis, lineNumber, begin, end, segment} =
  let content = maybeCharToChar <$> segment
  in mkStrip axis lineNumber begin end content

lineStrip :: Axis -> Coordinate -> String -> Int -> ByteCount -> Strip
lineStrip axis lineNumber line offset size =
  mkStrip axis lineNumber offset (offset + size - 1) stringContent
    where stringContent = (take size . drop offset) line

blackWhiteToChar :: BlackWhite Char -> Char
blackWhiteToChar blackWhiteChar = BlackWhite.toValueWithDefaults blackWhiteChar WordUtil.blackChar WordUtil.blankChar

maybeCharToChar :: Maybe Char -> Char
maybeCharToChar Nothing = WordUtil.blankChar
maybeCharToChar (Just ch) = ch

stripFromBlackWhiteLine :: Axis -> Coordinate -> [BlackWhite Char] -> Int -> ByteCount -> Strip
stripFromBlackWhiteLine axis lineNumber blackWhites offset size =
  let lineAsString = blackWhiteToChar <$> blackWhites
  in lineStrip axis lineNumber lineAsString offset size

allStripsInBlackWhiteLine :: Axis -> Coordinate -> [BlackWhite Char] -> [Strip]
allStripsInBlackWhiteLine axis lineNumber blackWhites =
  let lineAsString = blackWhiteToChar <$> blackWhites
  in stripsInLine axis lineNumber lineAsString

stripsInLine :: Axis -> Int -> String -> [Strip]
stripsInLine axis lineNumber chars = do
  let dimension = length chars
  offset <- [0 .. (dimension - 1)]
  size <- [1 .. (dimension - offset - 1)]
  return $ lineStrip axis lineNumber chars offset size

stripPoint :: Strip -> Coordinate -> Point
stripPoint Strip {axis, lineNumber, begin} offset =
  case axis of
  Axis.X -> Point lineNumber (begin + offset)
  Axis.Y -> Point (begin + offset) lineNumber

hasAnchor :: Strip -> Bool
hasAnchor strip @ Strip { letters } = length letters > 0

hasBlanks :: Strip -> Bool
hasBlanks Strip {blanks} = blanks > 0

isDense :: Strip -> Int -> Bool
isDense strip @ Strip {blanks} maxBlanks = hasAnchor strip && blanks <= maxBlanks

blankPoints :: Strip -> [Point]
blankPoints strip @ Strip {content} =
  let blankOffsets = filter (\offset -> WordUtil.isBlankChar (content !! offset)) [0 .. length content - 1]
  in stripPoint strip <$> blankOffsets

-- TODO. Redundant. See stripPoint.
pointAtOffset :: Strip -> Int -> Point
pointAtOffset Strip {lineNumber, begin, axis} offset =
  case axis of
    Axis.X -> Point lineNumber (begin + offset)
    Axis.Y -> Point (begin + offset) lineNumber

stripLength :: Strip -> Int
stripLength Strip {begin, end} = end - begin + 1

offset :: Strip -> Point -> Int
offset Strip {begin, axis} Point {row, col} =
    let indexInLine = case axis of
                      Axis.X -> col
                      Axis.Y -> row
    in indexInLine - begin

fillBlankInStrip :: Point -> Char -> Strip -> String
fillBlankInStrip point ch strip @ Strip { content }=
  MiscUtil.setListElement content (offset strip point) ch

