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
  ) where

import Data.Map (Map)
import qualified Data.List as List
import qualified Data.Map as Map
-- import qualified Data.ByteString.Char8 as BS
-- import Data.ByteString.Char8 (ByteString)

import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
-- import qualified Bolour.Grid.GridValue as GridValue
import qualified Bolour.Grid.Point as Axis
import Bolour.Grid.Point (Coordinate)
import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import qualified BoardGame.Util.WordUtil as WordUtil
import BoardGame.Server.Domain.Board (Board, Board(Board))
import qualified BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Strip (Strip, Strip(Strip), GroupedStrips)
import qualified BoardGame.Server.Domain.Strip as Strip
import qualified BoardGame.Server.Domain.CrossWordFinder as CrossWordFinder
import BoardGame.Server.Domain.WordDictionary (WordDictionary)
import qualified BoardGame.Server.Domain.WordDictionary as WordDictionary
import Bolour.Grid.SparseGrid (SparseGrid)
import qualified Bolour.Grid.SparseGrid as SparseGrid

import Bolour.Util.MiscUtil as MiscUtil

blank = Piece.emptyChar

-- | We know that the word and the strip have the same length.
--   So just check that the word matches the non-blank positions of the strip.
--   TODO. Inner loop. Should be made as efficient as possible.
wordFitsContent :: String -> DictWord -> Bool
wordFitsContent stripContent word
  | null stripContent && null word = True
  | null stripContent || null word = False -- TODO. This case should not be necessary. Assert equal length.
  | otherwise =
     let stripHead = head stripContent
         stripTail = tail stripContent
         wordHead = head word
         wordTail = tail word
     in (stripHead == blank || stripHead == wordHead) && wordFitsContent stripTail wordTail
     -- TODO. Does the compiler optimize this to tail-recursive? Otherwise use explicit if-then-else.

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
  let conformantStrips =
        if Board.isEmpty board then playableEmptyStrips board
        else playableStrips board trayCapacity
      mapByValue = MiscUtil.mapFromValueList valuation conformantStrips
      blankMapMaker = MiscUtil.mapFromValueList Strip.blanks
    in blankMapMaker <$> mapByValue

playableStrips :: Board -> Int -> [Strip]
playableStrips board trayCapacity =
  let strips = computeAllStrips board
      playableBlanks Strip {blanks} = blanks > 0 && blanks <= trayCapacity
      playables = filter playableBlanks strips
      playables' = filter Strip.hasAnchor playables
      playables'' = filter (stripIsDisconnectedInLine board) playables'
   in playables''

computeAllStrips :: Board -> [Strip]
computeAllStrips Board {grid} =
  let gridStrips = SparseGrid.lineSegments grid
  in gridStripToStrip <$> gridStrips

playableEmptyStrips :: Board -> [Strip]
playableEmptyStrips board @ Board {dimension}=
  let center = dimension `div` 2
      centerRowAsString = Board.rowsAsStrings board !! center
      strips = Strip.stripsInLine Axis.X dimension center centerRowAsString
      includesCenter Strip {begin, end} = begin <= center && end >= center
  in filter includesCenter str

gridStripToStrip :: (Axis.Axis, Coordinate, Coordinate, Int, [Maybe Piece]) -> Strip
gridStripToStrip (axis, lineNumber, offset, size, maybeCharList) =
  Strip.mkStrip axis lineNumber offset (offset + size - 1) content
    where content = (Piece.value . Piece.fromMaybe) <$> maybeCharList

-- | Check that a strip has no neighbors on either side - is disconnected
--   from the rest of its line. If it is has neighbors, it is not playable
--   since a matching word will run into the neighbors. However, a containing
--   strip will be playable and so we can forget about this strip.
stripIsDisconnectedInLine :: Board -> Strip -> Bool
stripIsDisconnectedInLine board (strip @ Strip {axis, begin, end, content})
  | (null content) = False
  | otherwise =
      let f = Strip.stripPoint strip 0
          l = Strip.stripPoint strip (end - begin)
          -- limit = dimension
          maybePrevPiece = Board.prev board f axis
          maybeNextPiece = Board.next board l axis
          isSeparator maybePiece =
            case maybePiece of
              Nothing -> True
              Just piece -> Piece.isEmpty piece
      in isSeparator maybePrevPiece && isSeparator maybeNextPiece

emptyCenterStrip :: ByteCount -> Coordinate -> Strip
emptyCenterStrip len dimension =
  let center = dimension `div` 2
      mid = len `div` 2
      line = List.replicate dimension Piece.emptyChar
  in Strip.lineStrip Axis.X center line (center - mid) len

mkEmptyCenterStripMapElement :: ByteCount -> Coordinate -> (ByteCount, Map BlankCount [Strip])
mkEmptyCenterStripMapElement len dimension =
  let strips = [emptyCenterStrip len dimension]
      blankCount = len
  in (len, Map.singleton len strips)

emptyCenterStripsByLengthByBlanks :: Coordinate -> Map ByteCount (Map BlankCount [Strip])
emptyCenterStripsByLengthByBlanks dimension =
  Map.fromList $ flip mkEmptyCenterStripMapElement dimension <$> [2 .. dimension]


