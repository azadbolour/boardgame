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
import BoardGame.Common.Domain.GridValue (GridValue)
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.Player (Player)
import BoardGame.Common.Message.GameDto (GameDto)

addPlayer :: Player -> Manager -> BaseUrl -> ClientM ()
startGame :: (GameParams, [GridValue Piece], [Piece], [Piece]) -> Manager -> BaseUrl -> ClientM GameDto
commitPlay :: String -> [PlayPiece] -> Manager -> BaseUrl -> ClientM [Piece]
machinePlay :: String -> Manager -> BaseUrl -> ClientM [PlayPiece]
swapPiece :: String -> Piece -> Manager -> BaseUrl -> ClientM Piece
endGame :: String -> Manager -> BaseUrl -> ClientM ()

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