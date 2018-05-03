--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}

module BoardGame.Server.Domain.GameBase (
    GameBase(..)
  , mkInitialBase
)
where

import qualified Data.ByteString.Lazy.Char8 as BC
import Data.Time (UTCTime, getCurrentTime)
import GHC.Generics
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (MonadError(..))

import qualified Bolour.Util.MiscUtil as Util (mkUuid)
import BoardGame.Common.Domain.PieceProviderType (PieceProviderType)
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.InitPieces (InitPieces, InitPieces(InitPieces))
import qualified BoardGame.Common.Domain.InitPieces as InitPieces
import BoardGame.Common.Domain.InitPieces (InitPieces)
import qualified BoardGame.Common.Domain.InitPieces as InitPieces
import qualified BoardGame.Server.Domain.Player as Player
import BoardGame.Server.Domain.GameError (GameError)
import BoardGame.Server.Domain.Player (Player, Player(Player))
import BoardGame.Server.Domain.Tray (Tray)
import qualified BoardGame.Server.Domain.Tray as Tray
import BoardGame.Server.Domain.PieceProvider (PieceProvider)
import qualified BoardGame.Server.Domain.PieceProvider as PieceProvider

-- Note. Excludes initial board to save space.
-- Initial board is reconstructed by using InitPiece {piecePoints}.

-- | The base state of the game - properties that are conceptually
--   immutable once set, and can be used to reconstitute the initial state
--   of the game.
data GameBase = GameBase {
    gameId :: String
  , gameParams :: GameParams
  , pointValues :: [[Int]]
  , initPieces :: InitPieces
  , initTrays :: [Tray]
  -- , playerName :: String
  , playerId :: String
  , startTime :: UTCTime
  , endTime :: Maybe UTCTime
}
  deriving (Eq, Show, Generic)

instance FromJSON GameBase
instance ToJSON GameBase

mkInitialBase :: (MonadError GameError m, MonadIO m) =>
  GameParams -> [[Int]] -> InitPieces -> Player -> PieceProvider -> m (GameBase, PieceProvider)

mkInitialBase gameParams pointValues initPieces player pieceProvider = do
  let GameParams { dimension, trayCapacity, languageCode} = gameParams
  let InitPieces {userPieces, machinePieces} = initPieces
  let Player {playerId, name = playerName} = player
  gameId <- Util.mkUuid
  startTime <- liftIO getCurrentTime
  (userTray, pieceProvider') <- Tray.mkTray pieceProvider trayCapacity userPieces
  (machineTray, pieceProvider'') <- Tray.mkTray pieceProvider' trayCapacity machinePieces
  let trays = [userTray, machineTray]
      endTime = Nothing
      base = GameBase gameId gameParams pointValues initPieces trays
             playerId startTime endTime
  return (base, pieceProvider'')


