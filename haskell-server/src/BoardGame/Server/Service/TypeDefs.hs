--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Service.TypeDefs where

import Control.Monad.Except (ExceptT)
import BoardGame.Server.Domain.GameError (GameError)

type Result res = ExceptT GameError IO res
type ID = String
type GameId = ID
type PlayerId = ID
type JsonEncoded = String
