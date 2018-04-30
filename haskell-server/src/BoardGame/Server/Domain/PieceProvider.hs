--
-- Copyright 2017-2018 Azad Bolour
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
    PieceProvider(..)
  , BoardGame.Server.Domain.PieceProvider.take
  , takePieces
  , swapOne
  , pieceProviderType
  , mkDefaultCyclicPieceProvider
  )
  where

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.Piece (Piece, Piece(Piece))
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType
import BoardGame.Common.Domain.PieceProviderType
import BoardGame.Server.Domain.GameError (GameError)

-- The piece generator types are closed in this implementation.
-- TODO. Would be nice to have an open piece generator implementation model.
-- Had some type system issues using type classes.

-- TODO. Name cyclic constructor parameters.

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
data PieceProvider =
  RandomPieceProvider { counter :: Integer, randomizer :: IO Char} |
  CyclicPieceProvider Integer String

take :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)

take (provider @ RandomPieceProvider {counter, randomizer}) = do
  letter <- liftIO $ randomizer
  let piece = Piece letter (show counter)
  let nextProvider = RandomPieceProvider (counter + 1) randomizer
  return (piece, nextProvider)

take (CyclicPieceProvider count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicPieceProvider count' (drop 1 cycler))

-- TODO. Best practices to disambiguate against Prelude [take]?
take' :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)
take' = BoardGame.Server.Domain.PieceProvider.take

takePieces :: (MonadError GameError m, MonadIO m) => PieceProvider -> Int -> m ([Piece], PieceProvider)
takePieces provider max = takePiecesAux provider [] max

takePiecesAux :: (MonadError GameError m, MonadIO m) => PieceProvider -> [Piece] -> Int -> m ([Piece], PieceProvider)
takePiecesAux provider list n =
  if n <= 0
    then return (list, provider)
    else do
      (piece, provider1) <- take' provider
      (pieces, provider2) <- takePiecesAux provider1 (piece:list) (n - 1)
      return (pieces, provider2)

swapOne :: (MonadError GameError m, MonadIO m) => PieceProvider -> Piece -> m (Piece, PieceProvider)
swapOne provider piece = do
  (swappedPiece, provider1) <- take' provider
  -- provider2 <- give provider1 piece
  return (swappedPiece, provider1)

pieceProviderType :: PieceProvider -> PieceProviderType
pieceProviderType (RandomPieceProvider _ _) = PieceProviderType.Random
pieceProviderType (CyclicPieceProvider _ _) = PieceProviderType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultCyclicPieceProvider :: PieceProvider
mkDefaultCyclicPieceProvider = CyclicPieceProvider 0 (cycle caps)
