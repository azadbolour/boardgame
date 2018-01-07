--
-- Copyright 2017 Azad Bolour
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
import BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray as Tray

import qualified BoardGame.Common.Domain.Player as Player
import qualified BoardGame.Server.Domain.Game as Game
import qualified BoardGame.Server.Domain.TileSack as TileSack
import BoardGame.Server.Domain.TileSack
import BoardGame.Common.Domain.PieceGeneratorType
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType

dummyDay :: Day
dummyDay = fromGregorian 2000 1 1

zeroDiffTime :: DiffTime
zeroDiffTime = secondsToDiffTime 0

dummyUTCTime :: UTCTime
dummyUTCTime = UTCTime dummyDay zeroDiffTime

class Converter entity dto where
  toEntity :: dto -> entity
  toDto :: entity -> dto

gameToStartGameResponse (Game {gameId, languageCode, board, trays, playerName, tileSack}) =
   let dimension = Board.dimension board
       genType = TileSack.pieceGeneratorType tileSack
       Tray {capacity, pieces = trayPieces} = trays !! Player.userIndex
       gameParams = GameParams dimension capacity languageCode playerName genType
   in StartGameResponse gameId gameParams (Board.getGridPieces board) trayPieces
