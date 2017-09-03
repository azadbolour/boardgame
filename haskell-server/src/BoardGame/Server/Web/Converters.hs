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
  )
  where

-- TODO. How to implement generic converters in Haskell?

import Data.Time
import BoardGame.Common.Message.GameDto as GameDto
import BoardGame.Server.Domain.Game(Game, Game(Game))
import BoardGame.Server.Domain.Board as Board
import BoardGame.Server.Domain.Tray as Tray

import qualified BoardGame.Common.Domain.Player as Player
import qualified BoardGame.Server.Domain.Game as Game
import BoardGame.Server.Domain.Game (Game, Game(Game))
import qualified BoardGame.Server.Domain.RandomPieceGenerator as RandomPieceGenerator

-- import qualified BoardGame.Server.Domain.LanguageDictionary as LanguageDictionary
-- import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary, LanguageDictionary(LanguageDictionary))

dummyDay :: Day
dummyDay = fromGregorian 2000 1 1

zeroDiffTime :: DiffTime
zeroDiffTime = secondsToDiffTime 0

dummyUTCTime :: UTCTime
dummyUTCTime = UTCTime dummyDay zeroDiffTime


class Converter entity dto where
  toEntity :: dto -> entity
  toDto :: entity -> dto

instance Converter Game GameDto.GameDto where
  -- TODO. Using dummy playNumber, playTurn, and score. Fix later.
  toEntity dto = Game
    gameId
    languageCode
    (mkBoardFromGridPieces height width gridPieces)
    [(Tray trayCapacity trayPieces), dummyMachineTray]
    playerName
    0
    Player.UserPlayer
    RandomPieceGenerator.mkRandomPieceGenerator
    [0, 0]
    dummyUTCTime
    where
      GameDto {gameId, languageCode, height, width, trayCapacity, gridPieces, trayPieces, playerName} = dto
      dummyMachineTray = Tray 0 [] -- TODO. This is a hack. toEntity should be disallowed.
  toDto entity = GameDto gameId languageCode (Board.height board) (Board.width board) (Tray.capacity userTray) (Board.getGridPieces board) (Tray.pieces userTray) playerName where
      gameId = Game.gameId entity
      languageCode = Game.languageCode entity
      board = Game.board entity
      trays = Game.trays entity
      playerName = Game.playerName entity
      -- Game {gameId, languageCode, board, trays, playerName} = entity -- no can do with existentially-quantified data
      userTray = trays !! Player.userIndex





