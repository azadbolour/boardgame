--
-- Copyright 2017-2018 Azad Bolour
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
  , closeGame
  )
  where

-- (Manager)
import Network.HTTP.Client (newManager, defaultManagerSettings)
import Servant.API ((:<|>)(..))
import Servant.Client (BaseUrl, client, ClientM)
-- import Servant.Common.Req (ClientM)
import BoardGame.Common.Domain.GameParams
import qualified BoardGame.Common.GameApi as GameApi
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.PlayerDto (PlayerDto)
import BoardGame.Common.Message.StartGameRequest (StartGameRequest)
import BoardGame.Common.Message.HandShakeResponse (HandShakeResponse)
import BoardGame.Common.Message.StartGameResponse (StartGameResponse)
import BoardGame.Common.Message.SwapPieceResponse (SwapPieceResponse)
import BoardGame.Common.Message.CommitPlayResponse
import BoardGame.Common.Message.MachinePlayResponse
import BoardGame.Common.Domain.GameSummary (GameSummary)

handShake :: ClientM HandShakeResponse
addPlayer :: PlayerDto -> ClientM ()
startGame :: StartGameRequest -> ClientM StartGameResponse
commitPlay :: String -> [PlayPiece] -> ClientM CommitPlayResponse
machinePlay :: String -> ClientM MachinePlayResponse
swapPiece :: String -> Piece -> ClientM SwapPieceResponse
closeGame :: String -> ClientM GameSummary

handShake
  :<|> addPlayer
  :<|> startGame
  :<|> commitPlay
  :<|> machinePlay
  :<|> swapPiece
  :<|> closeGame
  = client GameApi.gameApi

-- Note. In Servant 6.1 we have:
--   type ClientM = ExceptT ServantError IO
-- In later versions the type has changed to something more complicated.
-- Check the API docs and look for helper functions to convert that monad to an IO.
