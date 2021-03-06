--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.ServiceTestFixtures (
    module BoardGame.Server.Service.BaseServiceFixtures
  , makePlayer
  , makeGame
  , testDimension
  , testTrayCapacity
  ) where

import Data.Either
import Control.Monad.Trans.Except (runExceptT)
import Bolour.Util.SpecUtil (satisfiesRight) -- satisfiesJust
-- import BoardGame.Common.Domain.Player (Player(Player))
import BoardGame.Common.Domain.InitPieces (InitPieces(InitPieces))
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.PiecePoint (PiecePoint)
import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Server.Domain.Game (Game)
import BoardGame.Server.Domain.GameEnv (GameEnv)
import qualified BoardGame.Server.Service.GameTransformerStack as TransformerStack
import BoardGame.Server.Service.BaseServiceFixtures
import qualified BoardGame.Server.Service.GameService as GameService

makePlayer :: GameEnv -> String -> IO ()
makePlayer env name = do
    -- let player = Player name
    eitherUnit <- runExceptT $ TransformerStack.runDefaultUnprotected env $ GameService.addPlayerService name
    satisfiesRight eitherUnit

makeGame :: GameEnv -> GameParams -> [PiecePoint] -> [Piece] -> [Piece] -> IO Game
makeGame env gameParams initialPiecePoints userTrayStartsWith machineTrayStartsWith = do
  let initPieces = InitPieces initialPiecePoints userTrayStartsWith machineTrayStartsWith
  eitherResult <- runExceptT $ TransformerStack.runDefaultUnprotected env $ GameService.startGameService
    gameParams initPieces []
  satisfiesRight eitherResult
  let (Right game) = eitherResult
  return game
