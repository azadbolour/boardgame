--
-- Copyright 2017-2018 Azad Bolour
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
  , findAndSetBoardBlackPoints
  ) where

import qualified Data.Set as Set
import Data.Map (Map)
import Data.List (foldl')
import qualified Data.Map as Map

import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
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
  let fits stripChar wordChar = WordUtil.isBlankChar stripChar || stripChar == wordChar
      fitList = zipWith fits stripContent word
  in foldl' (&&) True fitList

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

findMatchForStrips ::
     Board
  -> WordDictionary
  -> Map BlankCount [Strip]         -- ^ strips of a given length grouped by number of blanks
  -> Map ByteCount [LetterCombo]    -- ^ combinations of letters grouped by count
  -> Maybe (Strip, DictWord)

findMatchForStrips board dictionary stripsByBlanks combosByLength =
  -- Create a descending list of all: [(blanks, ([Strip], [combos]))] for strips of a given length.
  -- The strips have the given number of blanks.
  -- And the number of letters in each combo is also the number of blanks.
  -- So the combos can be used to fill the strips exactly.
  let matchedStripsAndCombos = Map.toDescList $ MiscUtil.zipMaps stripsByBlanks combosByLength
  in if null matchedStripsAndCombos then Nothing
     else findOptimalMatchForFittingCombos board dictionary matchedStripsAndCombos

findMatchForValue :: Board -> WordDictionary -> Int -> GroupedStrips -> Map ByteCount [LetterCombo] -> Maybe (Strip, DictWord)
findMatchForValue board dictionary value stripsByValueAndBlanks combosByLength = do
  stripsByBlanks <- Map.lookup value stripsByValueAndBlanks
  findMatchForStrips board dictionary stripsByBlanks combosByLength

-- | Find a best match (if any) for strips of at most a given length.
--   Recursive on the length limit.
--   Recursion allows us to break out as soon as we find a match at the limit.
--   Recursive matches will all be shorter and therefore inferior.
bestMatchUpToValue ::
     Board
  -> WordDictionary
  -> Int
  -> GroupedStrips
  -> Map ByteCount [LetterCombo]
  -> Maybe (Strip, DictWord)

bestMatchUpToValue board dictionary maxValue stripsByValueAndBlanks combosByLength
  | maxValue == 0 = Nothing
  | otherwise =
       let foundAtLimit = findMatchForValue board dictionary maxValue stripsByValueAndBlanks combosByLength
       in case foundAtLimit of
            Nothing -> bestMatchUpToValue board dictionary (maxValue - 1) stripsByValueAndBlanks combosByLength
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
      stripsByValueAndBlanks = groupedPlayableStrips board trayLength stripValue
      maxValue = maximum $ Map.keys stripsByValueAndBlanks
      combosByLength = WordUtil.computeCombosGroupedByLength trayContent
  in bestMatchUpToValue
       board dictionary maxValue stripsByValueAndBlanks combosByLength

-- | Groups the playable strips of the board by their "value", and within
--   a value by the number of blanks.
groupedPlayableStrips ::
     Board           -- ^ the board
  -> Int             -- ^ tray capacity - maximum number of blanks in a play strip
  -> (Strip -> Int)  -- ^ Valuation function for the strip.
  -> Map ByteCount (Map BlankCount [Strip])

groupedPlayableStrips board trayCapacity valuation =
  let playableStrips = Board.playableStrips board trayCapacity
      mapByValue = MiscUtil.mapFromValueList valuation playableStrips
      blankMapMaker = MiscUtil.mapFromValueList Strip.blanks
    in blankMapMaker <$> mapByValue

type Anchored = Bool
type MaskedStripContentExists = Bool

-- filterOnKey :: (key -> Bool) -> Map.Map key value -> Map.Map key value
-- filterOnKey keyPredicate map =
--   let keyValuePredicate k _ = keyPredicate k
--   in Map.filterWithKey keyValuePredicate map

-- | For each blank point, it it is solely covered by dense playable strips
--   in the given direction, return its covering strips in that direction.
--   If a blank point is not a key in the resulting map, then it is covered
--   by at least one non-dense strip, and we have to assume that it may be
--   covered by a play in that direction. If a blank point is a key in the
--   resulting map, then we know for sure that it is only covered by dense
--   strips, and by considering what words may be played on those dense
--   strips, we can efficiently determine if the blank point can never be
--   covered by a play along the given axis.
findDenselyEnclosedBlanks :: Board -> Int -> Axis -> Map.Map Point [Strip]
findDenselyEnclosedBlanks board maxBlanks axis =
  let blanksToStrips = Board.playableEnclosingStripsOfBlankPoints board axis
      allDense = all (`Strip.isDense` maxBlanks)
  in Map.filter allDense blanksToStrips

findAndSetBoardBlackPoints :: WordDictionary -> Board -> (Board, [Point])
findAndSetBoardBlackPoints dictionary board =
  let directDeadPoints = Set.toList $ hopelessBlankPoints board dictionary
      newBoard = Board.setBlackPoints board directDeadPoints
  in if null directDeadPoints then
       (newBoard, directDeadPoints)
     else
       let (b, moreDeadPoints) = findAndSetBoardBlackPoints dictionary newBoard
           allDeadPoints = directDeadPoints ++ moreDeadPoints
       in (b, allDeadPoints)

-- TODO. Move a util module.
caps :: String
caps = ['A' .. 'Z']

-- | Find useless blanks - blanks that cannot possibly be filled.caps.
--
--   Basic idea of the algorithm. The dictionary contains all masked words
--   with up to maxMaskedWords blanks. We find the points that are covered
--   only by dense strips of at most maxMaskedWords + 1 blanks in the X or Y direction.
--   Then we try all letters from A to Z on each such point. The resulting strips covering
--   that point now have maxMaskedWords blanks, and their content can be looked up
--   as masked words in the dictionary. If none of the contents exist, then the given
--   letter cannot cover that point. If no letter can cover that point, then
--   no play in the given direction could cover that point. The results for the
--   two directions are then combined to determine the useful/useless status of the point.
--   See also the doc comments for teh function noMatchInStripsForPoint which
--   does much of the legwork of the algorithm.
hopelessBlankPoints :: Board -> WordDictionary -> Set.Set Point
hopelessBlankPoints board dictionary @ WordDictionary { maxMaskedLetters } =
  let maxBlanks = maxMaskedLetters + 1
      hEnclosures = findDenselyEnclosedBlanks board maxBlanks Axis.X
      vEnclosures = findDenselyEnclosedBlanks board maxBlanks Axis.Y
      points = Set.fromList $ Map.keys hEnclosures ++ Map.keys vEnclosures
      stripListForPoint point =
        let hStrips = Map.findWithDefault [] point hEnclosures
            vStrips = Map.findWithDefault [] point vEnclosures
        in [(Axis.X, hStrips), (Axis.Y, vStrips)]
      pointIsHopeless point =
        let stripList = stripListForPoint point
        in all (\ch -> noMatchInStripsForPoint board dictionary point ch stripList) caps
  in Set.filter pointIsHopeless points

-- | For a blank point that is covered only by dense strips in some direction,
--   ( X or Y), determine whether covering the point by the given letter is
--   an impossible option: whether, if the given letter were to be played
--   to that point, no word would match it.
--
--   About the enclosingDenseStrips argument [(Axis, [Strip])]:
--
--   It is list of two 2-tuples, one each for the X and Y axis.
--   Each member of the list provides the list of dense strips covering
--   the given point argument in the given direction.
--
--   If the list of dense strips for a given direction is empty, some non-dense
--   strip in that direction may cover the point.
--
--   If the dense strip list is non-empty, we know that only the given strips,
--   all of which are dense, cover the strip in that direction.
--
--   Return True if we know for sure that no word can be played that
--   covers the given point with the given letter.
--
noMatchInStripsForPoint ::
     Board            -- ^ The existing board.
  -> WordDictionary   -- ^ The word dictionary.
  -> Point            -- ^ The blank point to be checked for possible coverage.
  -> Char             -- ^ The letter to cover the blank point.
  -> [(Axis, [Strip])]-- ^ The dense strips in each direction enclosing the blank point
  -> Bool
noMatchInStripsForPoint board dictionary point letter enclosingDenseStrips =
  let status (axis, strips) =
        (anchored, filledContentExists)
        where anchored = Board.pointHasRealNeighbor board point axis
              filledContentExists =
                let filledContents = Strip.fillBlankInStrip point letter <$> strips
                -- If the point has no dense enclosing strips, for all we know some non-dense
                -- strip can cover it. So pretend that it is covered by a match.
                in case filledContents of
                     [] -> True
                     _ -> any (WordDictionary.isMaskedWord dictionary) filledContents
      [(anchored1, exists1), (anchored2, exists2)] = status <$> enclosingDenseStrips
  in (not exists1 && not exists2) || (not exists1 && anchored1) || (not exists2 && anchored2)
