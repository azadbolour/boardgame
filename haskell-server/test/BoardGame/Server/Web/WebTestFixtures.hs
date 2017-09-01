--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

module BoardGame.Server.Web.WebTestFixtures (
    makePlayer
  , makeGame
  , thePlayer
  , params
  , initTest
  , centerGridPoint
  , centerGridPiece
  ) where

import Data.Char (toUpper)
import Control.Monad (forever)
import Control.Monad.Trans.Except (runExceptT)
import Bolour.Util.DbUtil (makePool)
import BoardGame.Server.Domain.GameConfig (Config(..), DeployEnv(..))
import qualified BoardGame.Server.Domain.GameConfig as Config
import qualified BoardGame.Server.Domain.GameConfig as ServerParameters
import Bolour.Util.SpecUtil (satisfiesRight) -- satisfiesJust
import BoardGame.Common.Domain.Player (Player, Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import BoardGame.Common.Domain.GridPiece (GridPiece)
import BoardGame.Common.Domain.GridValue (GridValue, GridValue(GridValue))
import qualified BoardGame.Common.Domain.GridValue as GridValue
import BoardGame.Common.Domain.Point (Point, Point(Point))
import BoardGame.Common.Domain.GameParams (GameParams, GameParams(GameParams))
import qualified BoardGame.Common.Domain.GameParams as GameParams
import BoardGame.Common.Message.GameDto (GameDto)
import BoardGame.Server.Domain.GameCache as GameCache
import BoardGame.Server.Service.GameDao (cleanupDb)
import BoardGame.Server.Domain.GameEnv (GameEnv, GameEnv(GameEnv))
import BoardGame.Server.Web.GameEndPoint (addPlayerHandler, startGameHandler)
import qualified BoardGame.Server.Domain.LanguageDictionary as Dict
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary)
-- import qualified Bolour.Util.StaticTextFileCache as FileCache
import qualified BoardGame.Server.Domain.DictionaryCache as DictCache

makePlayer :: LanguageDictionary dictionary =>
     GameEnv dictionary
  -> String
  -> IO ()
makePlayer env name = do
    let player = Player name
    eitherUnit <- runExceptT $ addPlayerHandler env player
    satisfiesRight eitherUnit

makeGame :: LanguageDictionary dictionary =>
  GameEnv dictionary -> GameParams -> [GridPiece] -> [Piece] -> [Piece] -> IO GameDto
makeGame env params initialGridPieces userTrayStartsWith machineTrayStartsWith =
  satisfiesRight
    =<< runExceptT (startGameHandler env (params, initialGridPieces, userTrayStartsWith, machineTrayStartsWith))

thePlayer = "You"
params = GameParams 9 9 12 Dict.defaultLanguageCode thePlayer

centerGridPoint =
  let GameParams.GameParams {height, width, trayCapacity, languageCode, playerName} = params
  in Point (height `div`2) (width `div` 2)

centerGridPiece :: Char -> IO GridPiece
centerGridPiece value = do
  piece <- Piece.mkPiece value
  return $ GridValue piece centerGridPoint

initTest :: LanguageDictionary dictionary =>
  IO (GameEnv dictionary)
initTest = do
  -- TODO. Use getServerParameters and provide a config file for test.
  let serverParameters = Config.defaultServerParameters
      ServerParameters.ServerParameters {maxActiveGames} = serverParameters
  thePool <- makePool serverParameters
  -- let cfg = Config thePool Test
  cfg <- Config.mkConfig serverParameters thePool
  cleanupDb cfg
  cache <- GameCache.mkGameCache maxActiveGames
  -- dictionaryCache <- FileCache.mkCache 100 (toUpper <$>)
  dictionaryCache <- DictCache.mkCache "" 100
  return $ GameEnv cfg cache dictionaryCache
