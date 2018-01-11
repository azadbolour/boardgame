--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--


{-|
Client-side Haskell language binding for the game REST api.

Servant .Client's client function automagically generates the Haskell
language bindings by using the api specification.
-}
module BoardGame.Client.GameClient (
    addPlayer
  , startGame
  , commitPlay
  , machinePlay
  , swapPiece
  , endGame
  )
  where

import Network.HTTP.Client (Manager)
import Servant.API ((:<|>)(..))
import Servant.Client (BaseUrl, client)
import Servant.Common.Req (ClientM)

import BoardGame.Common.Domain.GameParams
import qualified BoardGame.Common.GameApi as GameApi
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import Bolour.Grid.GridValue (GridValue)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.Player (Player)
import BoardGame.Common.Message.StartGameRequest (StartGameRequest)
import BoardGame.Common.Message.StartGameResponse (StartGameResponse)
import BoardGame.Common.Message.SwapPieceResponse (SwapPieceResponse)
import BoardGame.Common.Message.CommitPlayResponse
import BoardGame.Common.Message.MachinePlayResponse
import BoardGame.Common.Domain.GameSummary (GameSummary)

addPlayer :: Player -> Manager -> BaseUrl -> ClientM ()
startGame :: StartGameRequest -> Manager -> BaseUrl -> ClientM StartGameResponse
commitPlay :: String -> [PlayPiece] -> Manager -> BaseUrl -> ClientM CommitPlayResponse
machinePlay :: String -> Manager -> BaseUrl -> ClientM MachinePlayResponse
swapPiece :: String -> Piece -> Manager -> BaseUrl -> ClientM SwapPieceResponse
endGame :: String -> Manager -> BaseUrl -> ClientM GameSummary

addPlayer
  :<|> startGame
  :<|> commitPlay
  :<|> machinePlay
  :<|> swapPiece
  :<|> endGame = client GameApi.gameApi

-- Note. In Servant 6.1 we have:
--   type ClientM = ExceptT ServantError IO
-- In later versions the type has changed to something more complicated.
-- Check the API docs and look for helper functions to convert that monad to an IO.