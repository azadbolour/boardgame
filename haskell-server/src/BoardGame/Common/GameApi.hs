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

In requests and responses, the following json objects are used. See the respective
documentation for the corresponding data structures for a description of the
fields.

gameParams - Parameters of a game to start.

piece - A piece used in play - its value is the letter used in constructing words.

point - The position of a piece on the game board.

playPiece - A piece that participates in a word play - may have been moved in
the given play or have existed on the board.

The API

* Create a player.

>  "game" :> "player" :> ReqBody '[JSON] Player :> Post '[JSON] ()

@

   POST \/game\/player
   request: {playerName: playerName}
   response: ()

   example:

     {playerName: \"John\"}
@

* Start a game.

> "game" :> "game" :> ReqBody '[JSON] (GameParams, [GridValue Piece], [Piece], [Piece]) :> Post '[JSON] GameDto

The request body provides the parameters of the game, the initial grid pieces
to populate the board with (used for testing), the initial user tray pieces to use (used for testing),
and the initial machine tray pieces (used for testing). The response includes the game parameters,
the initial grid pieces of the game, and the user tray pieces. The initial condition of the game
provided in the body is used to put the game in a known state for testing.

@
    POST \/game\/game
    request: [
          gameParams
        , [{piece: piece, point: point}, ...]
        , [piece, ...]
        , [piece, ...]
      ]
    response: {
        gameId: gameId
      , languageCode: code,
      , height: height
      , width: width
      , trayCapacity: capacity
      , gridPieces: [{point: point, piece: piece}, ...]
      , trayPieces: [piece, ...]
      , playerName: name
      }

    example
      request: [{width: 9, height: 9, trayCapacity: 9, languageCode: \"en\", playerName: \"John\"}, [], [], []]
      response: {
          gameId: \"ea9cc739-3259-42f3-b11d-eb77499f3d81\"
        , languageCode: \"en\"
        , height: 9
        , width: 9
        , trayCapacity: 9
        , gridPieces: [{piece: {value: \"E\", id: \"0\"}, point: {row: 4, col: 4}, }]
        , trayPieces: [
              {value: \"S\", id: \"9\"}
            , {value: \"S\", id: \"8\"}
            , {value: \"O\", id: \"7\"}
            , {value: \"N\", id: \"6\"}
            , {value: \"A\", id: \"5\"}
            , {value: \"T\", id: \"4\"}
            , {value: \"P\", id: \"3\"}
            , {value: \"K\", id: \"2\"}
            , {value: \"L\", id: \"1\"}
          ]
        , playerName: \"John\"
        }
@

* Commit a  play by the user.

> "game" :> "commit-play" :> Capture "gameId" String :> ReqBody '[JSON] [PlayPiece] :> Post '[JSON] [Piece]

The request body provides a list of play pieces describing the play
being committed. The response body provides the list of replacement
pieces to replace the user tray pieces used in that play.

See 'BoardGame.Common.Domain.PlayPiece.PlayPiece'.

@
    POST \/game\/commit-play/{gameId}
    request: [
      {
        piece: piece
        point: point
        moved: bool
      },
      ...
    ]
    response: [piece, ...]

    example:
      POST \/game\/commit-play\/ea9cc739-3259-42f3-b11d-eb77499f3d81
      request: [
          {piece: {value: \"B\", id: \"2\"}, point: {row: 4, col: 3}, moved: true}
        , {piece: {value: \"E\", id: \"0"}, point: {row: 4, col: 4}, moved: false}
        , {piece: {value: \"T\", id: \"1\"}, point: {row: 4, col: 5}, moved: true}
      ]
      response: [{value: \"U\", id: \"20\"}, {value: \"A\", id: \"19\"}]
@

* Get the next machine play.

> "game" :> "machine-play" :> Capture "gameId" String :> Post '[JSON] [PlayPiece]

The request has an empty body. The response is a list of PlayPieces describing
the machine play (see 'BoardGame.Common.Domain.PlayPiece.PlayPiece').

@
    GET \/game\/machine-play\/{gameId}
    response: [
      {
        piece: piece
        point: point
        moved: bool
      },
      ...
    ]

    example:
      POST \/game\/machine-play\/4c5e218d-0bd5-429f-9649-b7d949b84be2
      response:
      [
          {piece: {value: \"C\", id: \"15\"}, point: {row: 2, col: 3}, moved: true}
        , {piece: {value: \"O\", id: \"16\"}, point: {row: 3, col: 3}, moved: true}
        , {piece: {value: \"O\", id: \"20\"}, point: {row: 4, col: 3}, moved: false}
        , {piece: {value: \"L\", id: \"14\"}, point: {row: 5, col: 3}, moved: true}
      ]

@

* Swap a piece for another.

> "game" :> "swap-piece" :> Capture "gameId" String :> ReqBody '[JSON] Piece :> Post '[JSON] Piece

The request is the piece to be swapped. The response is the new piece returned in exchange.

@
    POST \/game\/swap-piece\/{gameId}
    request: piece
    response: piece

    example:
      POST \/game\/swap-piece\/4c5e218d-0bd5-429f-9649-b7d949b84be2
      request: {value: \"Z\", id: \"15\"}
      response: {value: \"K\", id: \"45\"}
@

* End a game.

> "game" :> "end-game" :> Capture "gameId" String :> Post '[JSON] ()

@
    GET \/game\/end-game\/{gameId}
@
-}

module BoardGame.Common.GameApi (
    GameApi
  , gameApi
  , GameApi'
  , gameApi'
)
where

import Servant
import BoardGame.Common.Domain.GameParams (GameParams)
import BoardGame.Common.Domain.PlayPiece (PlayPiece)
import BoardGame.Common.Domain.GridValue (GridValue)
import BoardGame.Common.Message.GameDto (GameDto)
import BoardGame.Common.Message.CommitPlayResponse (CommitPlayResponse)
import BoardGame.Common.Message.MachinePlayResponse (MachinePlayResponse)
import BoardGame.Common.Message.GameDto (GameDto)
import BoardGame.Common.Message.StartGameRequest (StartGameRequest)
import BoardGame.Common.Domain.Player (Player)
import BoardGame.Common.Domain.Piece (Piece)

-- | The api interface for the game as a type. All paths have a "game" prefix.
type GameApi =
       "game" :> "player" :> ReqBody '[JSON] Player :> Post '[JSON] ()
  :<|> "game" :> "game" :> ReqBody '[JSON] StartGameRequest :> Post '[JSON] GameDto
  :<|> "game" :> "commit-play" :> Capture "gameId" String :> ReqBody '[JSON] [PlayPiece] :> Post '[JSON] CommitPlayResponse
  :<|> "game" :> "machine-play" :> Capture "gameId" String :> Post '[JSON] MachinePlayResponse
  :<|> "game" :> "swap-piece" :> Capture "gameId" String :> ReqBody '[JSON] Piece :> Post '[JSON] Piece
  :<|> "game" :> "end-game" :> Capture "gameId" String :> Post '[JSON] ()

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


