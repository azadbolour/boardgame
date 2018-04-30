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

module BoardGame.Server.Domain.Tray (
    Tray(..)
  , mkTray
  , replacePiece
  , replacePieces
  , findPieceIndexById
  , findPieceIndexByValue
  , removePieceByValue
  , isEmpty
)
where

import Data.List
import GHC.Generics
import Data.Aeson (FromJSON, ToJSON)
import Control.Monad.Except (MonadError(..))
import Control.Monad.IO.Class (MonadIO(..))

import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.PieceProvider (PieceProvider)
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import BoardGame.Server.Domain.GameError (GameError(..))
import Bolour.Util.MiscUtil (setListElement)

-- TODO. Keep the invariant that the tray is always full. Do not expose constructor.
-- Force the caller to give the right number of pieces - else error out.
-- | A user or machine tray containing pieces available for play.
data Tray = Tray {
    capacity :: Int
  , pieces :: [Piece]
}
  deriving (Eq, Show, Generic)

instance FromJSON Tray
instance ToJSON Tray

-- TODO. Validate capacity.
--   if capacity <= 0 then throwError $ InvalidTrayCapacityError capacity

-- mkTray :: [Piece] -> Tray
-- mkTray pieces = Tray (length pieces) pieces

mkTray :: (MonadError GameError m, MonadIO m) =>
  PieceProvider -> Int -> [Piece] -> m (Tray, PieceProvider)

mkTray pieceProvider capacity initPieces = do
  let needed = capacity - length initPieces
  (newPieces, provider') <- PieceProvider.takePieces pieceProvider needed
  let tray = Tray capacity (initPieces ++ newPieces)
  return (tray, provider')

isEmpty :: Tray -> Bool
isEmpty Tray { pieces } = null pieces

-- sumLetterWeights :: Tray -> Int
-- sumLetterWeights Tray { pieces } = sum $ Piece.worth <$> pieces

-- | Replace pieces in tray.
replacePieces :: Tray -> [Piece] -> [Piece] -> Tray
replacePieces (tray @ Tray {pieces = trayPieces}) originalPieces replacements =
  let remainingPieces = trayPieces \\ originalPieces
  in tray {pieces = remainingPieces ++ replacements}

findPieceIndexById :: (MonadError GameError m) => Tray -> String -> m Int
findPieceIndexById (Tray {pieces}) id =
  let maybeIndex = findIndex ((== id) . Piece.id) pieces
  in case maybeIndex of
       Nothing -> throwError $ PieceIdNotFoundError id
       Just index -> return index

findPieceIndexByValue :: (MonadError GameError m) => Tray -> Char -> m Int
findPieceIndexByValue (Tray {pieces}) pieceValue =
  let maybeIndex = findIndex ((== pieceValue) . Piece.value) pieces
  in case maybeIndex of
       Nothing -> throwError $ PieceValueNotFoundError pieceValue
       Just index -> return index

replacePiece :: Tray -> Int -> Piece -> Tray
replacePiece (tray @ Tray {pieces}) index piece =
  let pieces' = setListElement pieces index piece
  in tray {pieces = pieces'}

-- TODO. Check for existence.
-- If non-existence is harmful, throw error. Else should not be monadic.
removePieceByValue :: (MonadError GameError m) => Tray -> Char -> m (Piece, Tray)
removePieceByValue tray @ Tray {capacity, pieces} letter = do
  index <- findPieceIndexByValue tray letter
  let piece = pieces !! index
      remainingPieces = piece `delete` pieces
      tray' = Tray capacity remainingPieces
  return (piece, tray')

