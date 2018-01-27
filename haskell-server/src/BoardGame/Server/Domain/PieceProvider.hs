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
{-# LANGUAGE ScopedTypeVariables #-}

module BoardGame.Server.Domain.PieceProvider (
    PieceProvider(..),
    PieceProvider(RandomPieceProvider, CyclicPieceProvider)
  , length'
  , isEmpty
  , BoardGame.Server.Domain.PieceProvider.take
  , takeAvailableTiles
  , swapOne
  , pieceProviderType
  , mkDefaultPieceProvider
  )
  where

import Data.List
import qualified Data.List as List
import Data.Map as Map
import System.Random
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType
import BoardGame.Common.Domain.PieceProviderType
import Bolour.Util.MiscUtil (IOEither)
import BoardGame.Server.Domain.GameError (GameError, GameError(InternalError))

-- The piece generator types are closed in this implementation.
-- TODO. Would be nice to have an open piece generator implementation model.
-- So that new implementations of piece generator do not affect existing code.
-- Best practices in Haskell for extensible variants of a type?
-- Had some type system issues using type classes.

type SackContents = [Piece]
type InitialSackContents = SackContents

-- TODO. Name cyclic constructor parameters.

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
--   The string used in the cyclic generator has to be infinite.
data PieceProvider =
  RandomPieceProvider { initial :: InitialSackContents, current :: SackContents} |
  CyclicPieceProvider Integer String

isEmpty :: PieceProvider -> Bool
isEmpty (RandomPieceProvider initial current) = List.null current
isEmpty (CyclicPieceProvider count cycler) = False

isFull :: PieceProvider -> Bool
isFull (RandomPieceProvider initial current) = length initial == length current
isFull (CyclicPieceProvider count cycler) = False

length' :: PieceProvider -> Int
length' (RandomPieceProvider initial current) = length current
length' (CyclicPieceProvider count cycler) = maxBound :: Int

take :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)

take (sack @ RandomPieceProvider {initial, current}) =
  if isEmpty sack
    then throwError $ InternalError "attempt to take piece from empty sack" -- TODO. Specific game error.
    else do
      index <- liftIO $ randomRIO (0, (length' sack) - 1)
      let piece = current !! index
          current' = List.delete piece current
          sack' = sack { current = current' }
      return (piece, sack')

take (CyclicPieceProvider count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicPieceProvider count' (drop 1 cycler))

-- TODO. Better way to disambiguate?
take' :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)
take' = BoardGame.Server.Domain.PieceProvider.take

takeAvailableTilesToList :: (MonadError GameError m, MonadIO m) => PieceProvider -> [Piece] -> Int -> m ([Piece], PieceProvider)
takeAvailableTilesToList sack list n =
  if n == 0 || isEmpty sack
    then return (list, sack)
    else do
      (piece, sack1) <- take' sack -- Cannot fail if sack is non-empty.
      (pieces, sack2) <- takeAvailableTilesToList sack1 (piece:list) (n - 1)
      return (pieces, sack2)

takeAvailableTiles :: (MonadError GameError m, MonadIO m) => PieceProvider -> Int -> m ([Piece], PieceProvider)
takeAvailableTiles sack max = takeAvailableTilesToList sack [] max

give :: (MonadError GameError m, MonadIO m) => PieceProvider -> Piece -> m PieceProvider
give (sack @ RandomPieceProvider {initial, current}) piece =
  if isFull sack
    then throwError $ InternalError "attempt to give piece to a full sack" -- TODO. Specific game error.
    else return $ sack { current = piece:current }
    -- TODO. Check that piece belongs to initial contents.

give (sack @ (CyclicPieceProvider count cycler)) piece = return sack

-- give sack piece = return sack

swapOne :: (MonadError GameError m, MonadIO m) => PieceProvider -> Piece -> m (Piece, PieceProvider)
swapOne sack piece = do
  (swappedPiece, sack1) <- take' sack
  sack2 <- give sack1 piece
  return (swappedPiece, sack2)

pieceProviderType :: PieceProvider -> PieceProviderType
pieceProviderType (RandomPieceProvider _ _) = PieceProviderType.Random
pieceProviderType (CyclicPieceProvider _ _) = PieceProviderType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceProvider :: PieceProviderType -> Int -> PieceProvider
mkDefaultPieceProvider PieceProviderType.Random dimension =
  let init = mkInitialRandomSackContent dimension
  in RandomPieceProvider init init
mkDefaultPieceProvider PieceProviderType.Cyclic dimension = CyclicPieceProvider 0 (cycle caps)

mkInitialRandomSackContent :: Int -> [Piece]
mkInitialRandomSackContent dimension =
  let roughNumPieces = (dimension * dimension * 2) `div` 3
      (letterFrequencies, total) = Piece.normalizedFrequencies roughNumPieces
      contentLetters = do
        (ch, freq) <- Map.toList letterFrequencies
        replicate freq ch
      ids = show <$> [0 .. total - 1]
      lettersAndIds = zip contentLetters ids
  in mkPiece <$> lettersAndIds
       where mkPiece (ch, id) = Piece ch id

--       frequenciesFor15Board = Piece.frequencies
--       area15 :: Float = fromIntegral (15 * 15)
--       area :: Float = fromIntegral (dimension * dimension)
--       factor = area / area15
--       letters = do
--         (ch, num) <- frequenciesFor15Board
--         let f' = max 1 (round $ fromIntegral num * factor)
--         replicate f' ch
--       ids = [0 .. length letters]
--   in (\(ch, id) -> Piece ch (show id)) <$> zip letters ids

-- mkInitialRandomSackContent :: Int -> [Piece]
-- mkInitialRandomSackContent dimension =
--   let frequenciesFor15Board = Piece.frequencies
--       area15 :: Float = fromIntegral (15 * 15)
--       area :: Float = fromIntegral (dimension * dimension)
--       factor = area / area15
--       letters = do
--         (ch, num) <- frequenciesFor15Board
--         let f' = max 1 (round $ fromIntegral num * factor)
--         replicate f' ch
--       ids = [0 .. length letters]
--   in (\(ch, id) -> Piece ch (show id)) <$> zip letters ids
