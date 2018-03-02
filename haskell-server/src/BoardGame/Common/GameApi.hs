--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

{-|
Servant API for board game.

See http://haskell-servant.readthedocs.io/en/stable/tutorial/Server.html

-}

module BoardGame.Common.GameApi (
    GameApi
  , gameApi
  , GameApi'
  , gameApi'
)
where

import Servant
import Bolour.Plane.Domain.GridValue (GridValue)
import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Common.Message.CommitPlayResponse (CommitPlayResponse)
import BoardGame.Common.Message.MachinePlayResponse (MachinePlayResponse)
import BoardGame.Common.Message.StartGameRequest (StartGameRequest)
import BoardGame.Common.Message.StartGameResponse (StartGameResponse)
import BoardGame.Common.Message.SwapPieceResponse (SwapPieceResponse)
import BoardGame.Common.Domain.GameSummary (GameSummary)
import BoardGame.Common.Domain.Player (Player)
import BoardGame.Common.Domain.Piece (Piece)

-- | The api interface for the game as a type. All paths have a "game" prefix.
type GameApi =
       "game" :> "player" :> ReqBody '[JSON] Player :> Post '[JSON] ()
  :<|> "game" :> "game" :> ReqBody '[JSON] StartGameRequest :> Post '[JSON] StartGameResponse
  :<|> "game" :> "commit-play" :> Capture "gameId" String :> ReqBody '[JSON] [PlayPiece] :> Post '[JSON] CommitPlayResponse
  :<|> "game" :> "machine-play" :> Capture "gameId" String :> Post '[JSON] MachinePlayResponse
  :<|> "game" :> "swap-piece" :> Capture "gameId" String :> ReqBody '[JSON] Piece :> Post '[JSON] SwapPieceResponse
  :<|> "game" :> "close-game" :> Capture "gameId" String :> Post '[JSON] GameSummary

-- Note - In later servant versions this has changed - just use Raw.
type GameApi' = GameApi :<|> "boardgame" :> Raw

-- TODO. suspendGame, resumeGame.
-- Note Capture means it is an element of the path.
-- QueryParam means it is a query parameter. The type of the query parameter is given in the API.
-- But the handler gets a Maybe of that type since the query param may not be present.

-- |The api interface for the game as a value.
gameApi :: Proxy GameApi
gameApi = Proxy

gameApi' :: Proxy GameApi'
gameApi' = Proxy


