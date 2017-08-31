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

module BoardGame.Server.Domain.Tray (
    Tray(..)
  , mkTray
  , replacePiece
  , replacePieces
  , findPieceIndexById
  , findPieceIndexByValue
  , removePieceByValue
)
where

import Data.List
import Control.Monad.Except (MonadError(..))

import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Server.Domain.GameError(GameError(..))
import Bolour.Util.MiscUtil (setListElement)

-- | A user or machine tray containing pieces available for play.
data Tray = Tray {
    capacity :: Int
  , pieces :: [Piece]
}
  deriving (Show)

-- TODO. Validate capacity.
--   if capacity <= 0 then throwError $ InvalidTrayCapacityError capacity

mkTray :: [Piece] -> Tray
mkTray pieces = Tray (length pieces) pieces

-- | Replace pieces in tray.
replacePieces :: Tray -> [Piece] -> [Piece] -> Tray
replacePieces (tray @ Tray {pieces = trayPieces}) originalPieces replacements =
  let remainingPieces = trayPieces \\ originalPieces
  in mkTray (remainingPieces ++ replacements)

findPieceIndexById :: (MonadError GameError m) => Tray -> String -> m Int
findPieceIndexById (Tray {pieces}) pieceId =
  let maybeIndex = findIndex ((== pieceId) . Piece.pieceId) pieces
  in case maybeIndex of
       Nothing -> throwError $ PieceIdNotFoundError pieceId
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

removePieceByValue :: (MonadError GameError m) => Tray -> Char -> m (Piece, Tray)
removePieceByValue tray @ Tray {capacity, pieces} letter = do
  index <- findPieceIndexByValue tray letter
  let piece = pieces !! index
      remainingPieces = piece `delete` pieces
      tray' = Tray capacity remainingPieces
  return (piece, tray')

