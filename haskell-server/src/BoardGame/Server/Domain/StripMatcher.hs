--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.StripMatcher (
    wordFitsContent
  , findFittingWord
  , matchFittingCombos
  , findOptimalMatch
  , groupedPlayableStrips -- expose for testing
  , hopelessBlankPoints
  , hopelessBlankPointsForAxis
  , setHopelessBlankPointsAsDeadRecursive
  ) where

import qualified Data.Set as Set
import Data.Map (Map)
import Data.List (foldl')
import qualified Data.Map as Map
-- import qualified Data.ByteString.Char8 as BS
-- import Data.ByteString.Char8 (ByteString)

import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
-- import qualified Bolour.Plane.Domain.GridValue as GridValue
import qualified Bolour.Plane.Domain.Axis as Axis
import Bolour.Plane.Domain.Axis (Axis)
import Bolour.Plane.Domain.Point (Point)
import Bolour.Plane.Domain.Axis (Coordinate)
import Bolour.Language.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified Bolour.Language.Util.WordUtil as WordUtil
import BoardGame.Server.Domain.Board (Board, Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip), GroupedStrips)
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import Bolour.Language.Domain.WordDictionary (WordDictionary, WordDictionary(WordDictionary))
import qualified Bolour.Language.Domain.WordDictionary as WordDictionary

import Bolour.Util.MiscUtil as MiscUtil

-- | We know that the word and the strip have the same length.
--   So just check that the word matches the non-blank positions of the strip.
--   TODO. Inner loop. Should be made as efficient as possible.
wordFitsContent :: String -> DictWord -> Bool
wordFitsContent stripContent word =
  let fits stripChar wordChar = Strip.isBlankChar stripChar || stripChar == wordChar
      fitList = zipWith fits stripContent word
  in foldl' (&&) True fitList

-- wordFitsContent :: String -> DictWord -> Bool
-- wordFitsContent stripContent word
--   | null stripContent && null word = True
--   | null stripContent || null word = False -- For good measure!
--   | otherwise =
--      let stripHead = head stripContent
--          stripTail = tail stripContent
--          wordHead = head word
--          wordTail = tail word
--      in (Strip.isBlankChar stripHead || stripHead == wordHead) && wordFitsContent stripTail wordTail

-- | Find a match (if any) for a given strip.
--   Any match would do since our optimality measure is the total length
--   which is the length of the given strip. The combinations to try
--   are all of the right length to cover the strip's blanks.
findFittingWord ::
     Board
  -> WordDictionary
  -> BlankCount
  -> Strip                      -- ^ the strip
  -> [LetterCombo]              -- ^ combinations of letters to try on the strip's blanks
  -> Maybe (Strip, DictWord)    -- ^ longest word found if any

findFittingWord board dictionary numBlanks strip [] = Nothing
findFittingWord board dictionary numBlanks (strip @ Strip {letters, content}) (combo : combos) =
  let completeWordCombo = WordUtil.mergeLetterCombos letters combo
      words = WordDictionary.getWordPermutations dictionary completeWordCombo
      fittingWords = filter (wordFitsContent content) words
      crossWordFittingWords =
        filter crossWordsInDictionary fittingWords
          where crossWordsInDictionary word =
                  let crossWords = CrossWordFinder.findStripCrossWords board strip word
                  in all (WordDictionary.isWord dictionary) crossWords
   in case crossWordFittingWords of
      [] -> findFittingWord board dictionary numBlanks strip combos
      first : rest -> Just (strip, first)

matchFittingCombos ::
     Board
  -> WordDictionary
  -> BlankCount
  -> [Strip]
  -> [LetterCombo]
  -> Maybe (Strip, DictWord)

matchFittingCombos board dictionary numBlanks [] combos = Nothing
matchFittingCombos board dictionary numBlanks (strip : strips) combos =
  let maybeMatch = findFittingWord board dictionary numBlanks strip combos
  in case maybeMatch of
     Nothing -> matchFittingCombos board dictionary numBlanks strips combos
     Just match -> maybeMatch

-- | The fitting combos appears in descending order.
--   Each combo has exactly the same number of letters as needed to complete the corresponding strips.
findOptimalMatchForFittingCombos ::
     Board
  -> WordDictionary
  -> [(BlankCount, ([Strip], [LetterCombo]))]
  -> Maybe (Strip, DictWord)

findOptimalMatchForFittingCombos board dictionary [] = Nothing
findOptimalMatchForFittingCombos board dictionary ((count, (strips, combos)) : tail) =
  let maybeMatch = matchFittingCombos board dictionary count strips combos
  in case maybeMatch of
     Nothing -> findOptimalMatchForFittingCombos board dictionary tail
     Just match -> maybeMatch

-- | Find a best match (if any) for strips of a given length.
findOptimalMatchForStripsByLength ::
     Board
  -> WordDictionary
  -> Map BlankCount [Strip]         -- ^ strips of a given length grouped by number of blanks
  -> Map ByteCount [LetterCombo]    -- ^ combinations of letters grouped by count
  -> Maybe (Strip, DictWord)

findOptimalMatchForStripsByLength board dictionary stripsByBlanks combosByLength =
  -- Create a descending list of all: [(blanks, ([Strip], [combos]))] for strips of a given length.
  -- The strips have the given number of blanks.
  -- And the number of letters in each combo is also the number of blanks.
  -- So the combos can be used to fill the strips exactly.
  let matchedStripsAndCombos = Map.toDescList $ MiscUtil.zipMaps stripsByBlanks combosByLength
  in if null matchedStripsAndCombos then Nothing
     else findOptimalMatchForFittingCombos board dictionary matchedStripsAndCombos

-- | Find a best match (if any) for strips of at most a given length.
--   Recursive on the length limit.
--   Recursion allows us to break out as soon as we find a match at the limit.
--   Recursive matches will all be shorter and therefore inferior.
findOptimalMatchForStripsOfLimitedLength ::
     Board
  -> WordDictionary
  -> ByteCount
  -> GroupedStrips
  -> Map ByteCount [LetterCombo]
  -> Maybe (Strip, DictWord)

findOptimalMatchForStripsOfLimitedLength board dictionary limit groupedStrips combosByLength
  | limit <= 1 = Nothing
  | limit == 2 =
     do
       stripsByBlanks <- Map.lookup 2 groupedStrips
       findOptimalMatchForStripsByLength board dictionary stripsByBlanks combosByLength
  | otherwise =
       let foundAtLimit =
             do
                stripsByBlanks <- Map.lookup limit groupedStrips
                findOptimalMatchForStripsByLength board dictionary stripsByBlanks combosByLength
       in case foundAtLimit of
            Nothing -> findOptimalMatchForStripsOfLimitedLength board dictionary (limit - 1) groupedStrips combosByLength
            Just found -> return found

findOptimalMatch ::
     WordDictionary -- ^ the dictionary of available words to match
  -> Board      -- ^ the board
  -> String     -- ^ available characters that can be played
  -> Maybe (Strip, DictWord)

findOptimalMatch dictionary board trayContent =
  let dimension = Board.dimension board
      trayLength = length trayContent
      stripValue Strip {blanks} = blanks
      playableStrips = groupedPlayableStrips board trayLength stripValue
      playableCombos = WordUtil.computeCombosGroupedByLength trayContent
  in findOptimalMatchForStripsOfLimitedLength board dictionary dimension playableStrips playableCombos

-- | Get the strips of a two-dimensional grid of characters that can potentially house a word.
--   A strip is playable iff it has at least 1 anchor letter,
--   and at most c blanks, where c is the capacity of the tray.
groupedPlayableStrips ::
     Board        -- ^ the board
  -> Int          -- ^ tray capacity - maximum number of blanks in a play strip
  -> (Strip -> Int)  -- ^ Valuation function for the strip.
  -> Map ByteCount (Map BlankCount [Strip])

groupedPlayableStrips board trayCapacity valuation =
  let playableStrips = Board.playableStrips board trayCapacity
      mapByValue = MiscUtil.mapFromValueList valuation playableStrips
      blankMapMaker = MiscUtil.mapFromValueList Strip.blanks
    in blankMapMaker <$> mapByValue

-- gridStripToStrip :: (Axis.Axis, Coordinate, Coordinate, Int, [Maybe Piece]) -> Strip
-- gridStripToStrip (axis, lineNumber, offset, size, maybeCharList) =
--   Strip.mkStrip axis lineNumber offset (offset + size - 1) content
--     where content = (Piece.value . Piece.fromMaybe) <$> maybeCharList

hopelessBlankPointsForAxis :: Board -> WordDictionary -> Int -> Axis -> Set.Set Point
hopelessBlankPointsForAxis board dictionary @ WordDictionary {maxMaskedLetters} trayCapacity axis =
  let blanksToStrips = Board.playableEnclosingStripsOfBlankPoints board axis trayCapacity
      maxBlanks = maxMaskedLetters
      allDense = all (\s -> Strip.isDense s maxBlanks)
      stripsFilter predicate point strips = predicate strips
      denselyEnclosedBlanks = Map.filterWithKey (stripsFilter allDense) blanksToStrips
      stripMatchExists = any (\s @ Strip {content} -> WordDictionary.isMaskedWord dictionary content)
      stripsForHopelessBlanks = Map.filterWithKey (stripsFilter (not . stripMatchExists)) denselyEnclosedBlanks
  in
    Set.fromList $ Map.keys stripsForHopelessBlanks

-- TODO. Should change strips to have blanks instead of null chars for empty slots.
-- nullsToBlanks :: String -> String
-- nullsToBlanks s =
--   let nullToBlank ch = if Piece.isEmptyChar ch then ' ' else ch
--   in nullToBlank <$> s

hopelessBlankPoints :: Board -> WordDictionary -> Int -> Set.Set Point
hopelessBlankPoints board dictionary trayCapacity =
  let forX = hopelessBlankPointsForAxis board dictionary trayCapacity Axis.X
      (anchoredX, freeX) = Set.partition (\pt -> Board.pointHasRealNeighbor board pt Axis.X) forX
      forY = hopelessBlankPointsForAxis board dictionary trayCapacity Axis.Y
      (anchoredY, freeY) = Set.partition (\pt -> Board.pointHasRealNeighbor board pt Axis.Y) forY
  in
     Set.unions [anchoredX, anchoredY, Set.intersection freeX freeY]

setHopelessBlankPointsAsDeadRecursive :: Board -> WordDictionary -> Int -> (Board, [Point])
setHopelessBlankPointsAsDeadRecursive board dictionary trayCapacity =
  let directDeadPoints = Set.toList $ hopelessBlankPoints board dictionary trayCapacity
      newBoard = Board.setBlackPoints board directDeadPoints
  in if null directDeadPoints then
       (newBoard, directDeadPoints)
     else
       let (b, moreDeadPoints) = setHopelessBlankPointsAsDeadRecursive newBoard dictionary trayCapacity
           allDeadPoints = directDeadPoints ++ moreDeadPoints
       in (b, allDeadPoints)



