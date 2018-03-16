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
    PieceProvider(..),
    PieceProvider(RandomPieceProvider, CyclicPieceProvider)
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

-- TODO. Name cyclic constructor parameters.

-- | Piece generator.
--   Included in the common package to allow client tests
--   to generate pieces consistently with the server.
--   The string used in the cyclic generator has to be infinite.
data PieceProvider =
  RandomPieceProvider { counter :: Integer} |
  CyclicPieceProvider Integer String

isEmpty :: PieceProvider -> Bool
isEmpty (RandomPieceProvider _) = False
isEmpty (CyclicPieceProvider count cycler) = False

isFull :: PieceProvider -> Bool
isFull (RandomPieceProvider _) = False
isFull (CyclicPieceProvider count cycler) = False

take :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)

take (provider @ RandomPieceProvider {counter}) = do
  piece <- liftIO $ Piece.mkRandomPieceForId (show counter)
  let nextProvider = RandomPieceProvider (counter + 1)
  return (piece, nextProvider)

take (CyclicPieceProvider count cycler) = do
  let count' = count + 1
      piece = Piece (head cycler) (show count')
  return (piece, CyclicPieceProvider count' (drop 1 cycler))

-- TODO. Better way to disambiguate?
take' :: (MonadError GameError m, MonadIO m) => PieceProvider -> m (Piece, PieceProvider)
take' = BoardGame.Server.Domain.PieceProvider.take

takeAvailableTilesToList :: (MonadError GameError m, MonadIO m) => PieceProvider -> [Piece] -> Int -> m ([Piece], PieceProvider)
takeAvailableTilesToList provider list n =
  if n == 0 || isEmpty provider
    then return (list, provider)
    else do
      (piece, provider1) <- take' provider -- Cannot fail if provider is non-empty.
      (pieces, provider2) <- takeAvailableTilesToList provider1 (piece:list) (n - 1)
      return (pieces, provider2)

takeAvailableTiles :: (MonadError GameError m, MonadIO m) => PieceProvider -> Int -> m ([Piece], PieceProvider)
takeAvailableTiles provider max = takeAvailableTilesToList provider [] max

give :: (MonadError GameError m, MonadIO m) => PieceProvider -> Piece -> m PieceProvider
give (provider @ RandomPieceProvider {counter}) piece = return provider

give (provider @ (CyclicPieceProvider count cycler)) piece = return provider

swapOne :: (MonadError GameError m, MonadIO m) => PieceProvider -> Piece -> m (Piece, PieceProvider)
swapOne provider piece = do
  (swappedPiece, provider1) <- take' provider
  provider2 <- give provider1 piece
  return (swappedPiece, provider2)

pieceProviderType :: PieceProvider -> PieceProviderType
pieceProviderType (RandomPieceProvider _ ) = PieceProviderType.Random
pieceProviderType (CyclicPieceProvider _ _) = PieceProviderType.Cyclic

caps = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
mkDefaultPieceProvider :: PieceProviderType -> Int -> PieceProvider
mkDefaultPieceProvider PieceProviderType.Random dimension = RandomPieceProvider 0
mkDefaultPieceProvider PieceProviderType.Cyclic dimension = CyclicPieceProvider 0 (cycle caps)

-- mkInitialRandomSackContent :: Int -> [Piece]
-- mkInitialRandomSackContent dimension =
--   let roughNumPieces = (dimension * dimension * 2) `div` 3
--       (letterFrequencies, total) = Piece.normalizedFrequencies roughNumPieces
--       contentLetters = do
--         (ch, freq) <- Map.toList letterFrequencies
--         replicate freq ch
--       ids = show <$> [0 .. total - 1]
--       lettersAndIds = zip contentLetters ids
--   in mkPiece <$> lettersAndIds
--        where mkPiece (ch, id) = Piece ch id
