--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Web.WebTestFixtures (
    module BoardGame.Server.Service.BaseServiceFixtures
  , makePlayer
  , makeGame
  ) where

import Control.Monad.Trans.Except (runExceptT)
import Bolour.Util.SpecUtil (satisfiesRight) -- satisfiesJust
import BoardGame.Common.Domain.Player (Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Common.Message.StartGameResponse (StartGameResponse)
import BoardGame.Server.Domain.GameEnv (GameEnv)
import BoardGame.Server.Web.GameEndPoint (addPlayerHandler, startGameHandler)
import BoardGame.Server.Service.BaseServiceFixtures
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))

makePlayer :: GameEnv -> String -> IO ()
makePlayer env name = do
    let player = Player name
    eitherUnit <- runExceptT $ addPlayerHandler env player
    satisfiesRight eitherUnit

makeGame :: GameEnv -> GameParams -> [GridPiece] -> [Piece] -> [Piece] -> IO StartGameResponse
makeGame env gameParams initialGridPieces userTrayStartsWith machineTrayStartsWith =
  satisfiesRight
    =<< runExceptT (startGameHandler env (StartGameRequest gameParams initialGridPieces userTrayStartsWith machineTrayStartsWith))

-- runExceptT $ TransformerStack.runDefault gameEnv GameService.prepareDb