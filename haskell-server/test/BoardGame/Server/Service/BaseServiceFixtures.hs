--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Service.BaseServiceFixtures (
    thePlayer
  , gameParams
  , initTest
  , centerGridPoint
  , centerGridPiece
  ) where

import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import BoardGame.Common.Domain.Player (Player, Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Point (Point, Point(Point))
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import qualified BoardGame.Server.Domain.IndexedLanguageDictionary as Dict
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache
import qualified Bolour.Util.PersistRunner as PersistRunner
import qualified BoardGame.Server.Service.GameDao as GameDao

testConfigPath = "test-data/test-config.yml"
thePlayer = "You"
gameParams = GameParams 9 9 12 Dict.defaultLanguageCode thePlayer

centerGridPoint =
  let GameParams.GameParams {height, width, trayCapacity, languageCode, playerName} = gameParams
  in Point (height `div`2) (width `div` 2)

centerGridPiece :: Char -> IO GridPiece
centerGridPiece value = do
  piece <- Piece.mkPiece value
  return $ GridValue piece centerGridPoint

initTest :: IO GameEnv
initTest = do
  serverConfig <- ServerConfig.getServerConfig $ Just testConfigPath
  let ServerConfig {maxActiveGames, dbConfig} = serverConfig
  connectionProvider <- PersistRunner.mkConnectionProvider dbConfig
  GameDao.migrateDb connectionProvider
  GameDao.cleanupDb connectionProvider
  cache <- GameCache.mkGameCache maxActiveGames
  dictionaryCache <- DictCache.mkCache "" 100
  return $ GameEnv serverConfig connectionProvider cache dictionaryCache