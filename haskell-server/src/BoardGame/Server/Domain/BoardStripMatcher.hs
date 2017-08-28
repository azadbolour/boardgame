--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.BoardStripMatcher (
    wordMatcher
  , matchWordToStripsOfSameLength
  , findMatchesOnBoard
  , stripIsVacant
  , stripIsFull
  , metaRemoveVacantStrips
  , metaRemoveFullStrips
  , findMatchesForStrips
 )
  where

import Data.List

import BoardGame.Common.Domain.PlayPiece
import BoardGame.Common.Domain.Piece (Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.Grid (Grid(Grid))
import qualified BoardGame.Server.Domain.Grid as Grid
import qualified BoardGame.Common.Domain.PlayPiece as PlayPiece
import BoardGame.Common.Domain.GridValue (GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.Point
import BoardGame.Server.Domain.Play
import BoardGame.Server.Domain.Tray
import BoardGame.Server.Domain.Board

-- | Word is already taken.
type Mot = String

-- | Indicate that a piece if from a tray.
type TrayPiece = Piece

stripIsVacant :: [GridPiece] -> Bool
stripIsVacant = all (Piece.isNoPiece . GridValue.value)

removeVacantStrips :: [[GridPiece]] -> [[GridPiece]]
removeVacantStrips = filter (not . stripIsVacant)

metaRemoveVacantStrips :: [[[GridPiece]]] -> [[[GridPiece]]]
metaRemoveVacantStrips metaStrips = removeVacantStrips <$> metaStrips

stripIsFull :: [GridPiece] -> Bool
stripIsFull = all (Piece.isPiece . GridValue.value)

removeFullStrips :: [[GridPiece]] -> [[GridPiece]]
removeFullStrips = filter (not . stripIsFull)

metaRemoveFullStrips :: [[[GridPiece]]] -> [[[GridPiece]]]
metaRemoveFullStrips metaStrips = removeFullStrips <$> metaStrips

-- | Find every match of a list of word to the current state of the board
-- using letters from the tray. This is the main entry point to this module.
-- Returns a list of plays.
--
-- For each direction (horizontal and vertical) computes
-- lists of the strips of the board in that direction grouped
-- by length of strip; then for each word try matching only
-- against strips of the same length. Strips with no pieces
-- present, and strips with all positions filled are ruled out -
-- cannot play in those strips.
findMatchesOnBoard ::
  [Mot]
  -> Board                   -- ^ The board being matched.
  -> Tray                    -- ^ Supplies letters for filling blanks on the board to make up a word.
  -> [Play]                  -- ^ List of all matches found.

findMatchesOnBoard words (board @ (Board {grid})) (Tray { capacity, pieces }) =
  let Grid {cells = rows} = grid
      coordinatedRows = rows -- TODO. Redundant name. Fix.
      coordinatedCols = transpose coordinatedRows
      rowStripsByLength = Grid.matrixStripsByLength coordinatedRows
      rowStripsByLength' = metaRemoveVacantStrips rowStripsByLength
      rowStripsByLength'' = metaRemoveFullStrips rowStripsByLength'
      colStripsByLength = Grid.matrixStripsByLength coordinatedCols
      colStripsByLength' = metaRemoveVacantStrips colStripsByLength
      colStripsByLength'' = metaRemoveFullStrips colStripsByLength'
      stripsByLengthByAxis = [rowStripsByLength'', colStripsByLength'']
  in fst <$> findMatchesForStrips words board stripsByLengthByAxis pieces

-- | Indexing for the nested strips list is: axis, length, strip, grid cell.
findMatchesForStrips :: [Mot] -> Board -> [[[[GridPiece]]]] -> [TrayPiece] -> [(Play, [TrayPiece])]
findMatchesForStrips words board stripsByLengthByAxis trayPieces = do
  word <- words
  matchWordToStrips2D word board stripsByLengthByAxis trayPieces

-- | Try to match a given word to the board's strips in both directions.
--   Only strips that match the word's length are considered.
--   Filter out plays with moves that have cross-neighbors - for simplicity.
--   TODO. Allow cross neighbors if cross strip is a bona fide word.
--   Filter in just the strips that are disconnected in their line.
--   TODO. This last filtering should be done on strips earlier on.
--   Indexing for the nested strips list is: axis (0, 1 for X, Y), length, strip, grid cell.
matchWordToStrips2D :: Mot -> Board -> [[[[GridPiece]]]] -> [TrayPiece] -> [(Play, [TrayPiece])]
matchWordToStrips2D word board stripsByLengthByAxis trayPieces =
  let len = length word
      matcher strips =
        if length strips < len + 1 then []
        else matchWordToStripsOfSameLength word (strips !! len) trayPieces

      rowMatches = matcher (stripsByLengthByAxis !! 0)
      rowMatches' = filter (playHasNoCrossNeighbors board Y . fst) rowMatches
      rowMatches'' = filter (playIsDisconnectedInLine board X . fst) rowMatches'

      colMatches = matcher (stripsByLengthByAxis !! 1)
      colMatches' = filter (playHasNoCrossNeighbors board X . fst) colMatches
      colMatches'' = filter (playIsDisconnectedInLine board Y . fst) colMatches'

  in rowMatches'' ++ colMatches''

matchWordToStripsOfSameLength :: Mot -> [[GridPiece]] -> [TrayPiece] -> [(Play, [TrayPiece])]
matchWordToStripsOfSameLength word strips trayPieces =
  collectMaybes $ (\strip -> matchWordToStripOfSameLength word strip trayPieces) <$> strips

-- | Attempt to fill in the gaps in the strip by pieces from the tray.
matchWordToStripOfSameLength :: Mot -> [GridPiece] -> [TrayPiece] -> Maybe (Play, [TrayPiece])
matchWordToStripOfSameLength word strip trayPieces =
  toPlay <$> wordMatcher word strip trayPieces
     where toPlay (playPieces, trayPieces) = (Play playPieces, trayPieces)

-- | Match a single word against a single strip of the same length.
wordMatcher :: Mot -> [GridPiece] -> [TrayPiece] -> Maybe ([PlayPiece], [TrayPiece])
wordMatcher [] strip trayPieces = Just ([], trayPieces)
wordMatcher word [] trayPieces = Just ([], trayPieces) -- Redundant - for good measure.
wordMatcher (w:ws) (s:ss) trayPieces =
  let GridValue {value = piece, point} = s
      recurse aPiece moved restTray = do -- Maybe
        (playPieces, trayPieces') <- wordMatcher ws ss restTray
        let playPiece = PlayPiece aPiece point moved
        return (playPiece : playPieces, trayPieces')
  in if Piece.isNoPiece piece then do -- Maybe
       index <- findIndex ((== w) . Piece.value) trayPieces
       let piece = trayPieces !! index
       recurse piece True (trayPieces \\ [piece])
     else
       if Piece.value piece /= w then Nothing
       else recurse piece False trayPieces

collectMaybes :: [Maybe a] -> [a]
collectMaybes [] = []
collectMaybes (maybe : tail) =
  let rest = collectMaybes tail
  in case maybe of
     Nothing -> rest
     Just x -> x : rest

playHasNoCrossNeighbors :: Board -> Axis -> Play -> Bool
playHasNoCrossNeighbors board axis play =
  let movedGridPieces = movesOfPlay play
      points = GridValue.point <$> movedGridPieces
  in all (\point -> pointHasNoLineNeighbors board point axis) points

-- | Check that the play line segment has no neighbors - is disconnected
--   from the rest of its line.
playIsDisconnectedInLine :: Board -> Axis -> Play -> Bool
playIsDisconnectedInLine (Board {height, width, grid}) axis (Play []) = False
playIsDisconnectedInLine (Board {height, width, grid}) axis (Play {playPieces}) =
  let f = PlayPiece.point $ head playPieces
      l = PlayPiece.point $ last playPieces
      limit = case axis of
       X -> width
       Y -> height
      maybePrev = Grid.prevValue grid f axis limit
      maybeNext = Grid.nextValue grid l axis limit
      isSeparator maybePiece =
        case maybePiece of
          Nothing -> True
          Just (GridValue.GridValue {value = piece}) -> Piece.isNoPiece piece
  in isSeparator maybePrev && isSeparator maybeNext

-- debug (show gameError) $



