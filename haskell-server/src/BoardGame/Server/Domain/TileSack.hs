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

module BoardGame.Server.Domain.TileSack (
    TileSack(..),
    TileSack(RandomTileSack, CyclicTileSack)
  -- , next
  , length'
  , BoardGame.Server.Domain.TileSack.take
  , swapOne
  , pieceGeneratorType
  , mkDefaultPieceGen
  )
  where

import Data.List
import System.Random
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType
import BoardGame.Common.Domain.PieceGeneratorType
import Bolour.Util.MiscUtil (IOEither)
import BoardGame.Server.Domain.GameError (GameError, GameError(InternalError))

-- The piece generator types are closed in this implementation.
-- TODO. Would be nice to have an open piece generator implementation model.
-- So that new implementations of piece generator do not affect existing code.
-- What is the Haskell way of doing that?

type SackContents = [Piece]
type InitialSackContents = SackContents

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
--   The string used in the cyclic generator has to be infinite.
data TileSack = RandomTileSack { initial :: InitialSackContents, current :: SackContents} | CyclicTileSack Integer String

isEmpty :: TileSack -> Bool
isEmpty (RandomTileSack initial current) = null current
isEmpty (CyclicTileSack count cycler) = False

isFull :: TileSack -> Bool
isFull (RandomTileSack initial current) = length initial == length current
isFull (CyclicTileSack count cycler) = False

length' :: TileSack -> Int
length' (RandomTileSack initial current) = length current
length' (CyclicTileSack count cycler) = maxBound :: Int

take :: (MonadError GameError m, MonadIO m) => TileSack -> m (Piece, TileSack)

take (sack @ RandomTileSack {initial, current}) =
  if isEmpty sack
    then throwError $ InternalError "attempt to take piece from empty sack" -- TODO. Specific game error.
    else do
      index <- liftIO $ randomRIO (0, length' sack)
      let piece = current !! index
          current' = delete piece current
          sack' = sack { current = current' }
      return (piece, sack')

take (CyclicTileSack count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicTileSack count' (drop 1 cycler))

-- take sack = liftIO $ next sack

-- TODO. Better way to disambiguate?
take' :: (MonadError GameError m, MonadIO m) => TileSack -> m (Piece, TileSack)
take' = BoardGame.Server.Domain.TileSack.take

takeAvailableTilesToList :: (MonadError GameError m, MonadIO m) => TileSack -> [Piece] -> Int -> m ([Piece], TileSack)
takeAvailableTilesToList sack list n =
  if n == 0 || isEmpty sack
    then return (list, sack)
    else do
      (piece, sack1) <- take' sack -- Cannot fail if sack is non-empty.
      (pieces, sack2) <- takeAvailableTilesToList sack1 (piece:list) (n - 1)
      return (pieces, sack2)

takeAvailableTiles :: (MonadError GameError m, MonadIO m) => TileSack -> Int -> m ([Piece], TileSack)
takeAvailableTiles sack max = takeAvailableTilesToList sack [] max

give :: (MonadError GameError m, MonadIO m) => TileSack -> Piece -> m TileSack
give (sack @ RandomTileSack {initial, current}) piece =
  if isFull sack
    then throwError $ InternalError "attempt to give piece to a full sack" -- TODO. Specific game error.
    else return $ sack { current = piece:current }
    -- TODO. Check that piece belongs to initial contents.

give (sack @ (CyclicTileSack count cycler)) piece = return sack

-- give sack piece = return sack

swapOne :: (MonadError GameError m, MonadIO m) => TileSack -> Piece -> m (Piece, TileSack)
swapOne sack piece = do
  (swappedPiece, sack1) <- take' sack
  sack2 <- give sack1 piece
  return (swappedPiece, sack2)

-- next :: TileSack -> IO (Piece, TileSack)
-- next (RandomTileSack count) = do
--   let count' = count + 1
--   piece <- Piece.mkRandomPieceForId (show count')
--   return (piece, RandomTileSack count')
-- next (CyclicTileSack count cycler) = do
--   let count' = count + 1
--       piece = Piece (head cycler) (show count')
--   return (piece, CyclicTileSack count' (drop 1 cycler))

pieceGeneratorType :: TileSack -> PieceGeneratorType
pieceGeneratorType (RandomTileSack _ _) = PieceGeneratorType.Random
pieceGeneratorType (CyclicTileSack _ _) = PieceGeneratorType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceGen :: PieceGeneratorType -> Int -> TileSack
mkDefaultPieceGen PieceGeneratorType.Random dimension =
  let init = mkInitialRandomSackContent dimension
  in RandomTileSack init init
mkDefaultPieceGen PieceGeneratorType.Cyclic dimension = CyclicTileSack 0 (cycle caps)

mkInitialRandomSackContent :: Int -> [Piece]
mkInitialRandomSackContent dimension =
  let frequenciesFor15Board = Piece.frequencies
      area15 :: Float = fromIntegral (15 * 15)
      area :: Float = fromIntegral (dimension * dimension)
      factor = area / area15
      letters = do
        (ch, num) <- frequenciesFor15Board
        let f' = max 1 (round $ fromIntegral num * factor)
        replicate f' ch
      ids = [0 .. length letters]
  in (\(ch, id) -> Piece ch (show id)) <$> zip letters ids
