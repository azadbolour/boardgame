--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Web.Converters (
    Converter(..)
  , gameToStartGameResponse
  )
  where

import Data.Time
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Message.StartGameResponse as StartGameResponse
import BoardGame.Server.Domain.Game(Game, Game(Game))
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.GameBase(GameBase, GameBase(GameBase))
import qualified BoardGame.Server.Domain.GameBase as GameBase
import BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray as Tray
import qualified BoardGame.Server.Domain.Player as Player

import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider
import BoardGame.Server.Domain.PieceProvider
import BoardGame.Common.Domain.PieceProviderType
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

dummyDay :: Day
dummyDay = fromGregorian 2000 1 1

zeroDiffTime :: DiffTime
zeroDiffTime = secondsToDiffTime 0

dummyUTCTime :: UTCTime
dummyUTCTime = UTCTime dummyDay zeroDiffTime

class Converter entity dto where
  toEntity :: dto -> entity
  toDto :: entity -> dto

gameToStartGameResponse Game {gameBase, board, trays, pieceProvider} =
   let GameBase {gameId, gameParams} = gameBase
       GameParams {dimension, languageCode} = gameParams
       pieceProviderType = PieceProvider.pieceProviderType pieceProvider
       Tray {capacity, pieces = trayPieces} = trays !! Player.userIndex
   in StartGameResponse gameId gameParams (Board.getPiecePoints board) trayPieces
