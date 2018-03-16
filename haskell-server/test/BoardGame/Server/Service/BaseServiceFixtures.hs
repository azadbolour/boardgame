--
-- Copyright 2017-2018 Azad Bolour
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
  , testDimension
  , testTrayCapacity
  ) where

import BoardGame.Server.Domain.ServerConfig (ServerConfig, ServerConfig(ServerConfig), DeployEnv(..))
import qualified BoardGame.Server.Domain.ServerConfig as ServerConfig
import BoardGame.Common.Domain.Player (Player, Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import Bolour.Plane.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified Bolour.Plane.Domain.GridValue as GridValue
import Bolour.Plane.Domain.Point (Point, Point(Point))
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import qualified BoardGame.Server.Domain.GameEnv as GameEnv
import qualified Bolour.Language.Domain.WordDictionary as Dict
import qualified Bolour.Language.Domain.DictionaryCache as DictCache
import qualified Bolour.Language.Domain.DictionaryIO as DictIO
import qualified Bolour.Util.PersistRunner as PersistRunner
import qualified BoardGame.Server.Service.GameDao as GameDao
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType
import Control.Monad.Except (ExceptT(ExceptT), runExceptT)

testConfigPath = "test-data/test-config.yml"
thePlayer = "You"
testDimension = 5
center = testDimension `div` 2
testTrayCapacity = 3
pieceProviderType = PieceProviderType.Cyclic

-- gameParams = GameParams testDimension testTrayCapacity Dict.defaultLanguageCode thePlayer pieceProviderType
gameParams = GameParams testDimension testTrayCapacity "tiny" thePlayer pieceProviderType

centerGridPoint = Point center center

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
  dictionaryDir <- GameEnv.getDictionaryDir "data"
  -- dictionaryCache <- DictCache.mkCache dictionaryDir 100 2
  Right dictionaryCache <- runExceptT $ DictIO.readAllDictionaries dictionaryDir ["tiny"] ServerConfig.maxDictionaries ServerConfig.dictionaryMaxMaskedLetters
  return $ GameEnv serverConfig connectionProvider cache dictionaryCache