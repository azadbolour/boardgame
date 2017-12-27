module Main where

import Control.Monad.Except (runExceptT)

import Network.HTTP.Client (Manager, newManager, defaultManagerSettings)
import Servant.Client
import Servant.Common.BaseUrl()

import BoardGame.Common.Domain.Player (Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.Point (Point(Point))
import qualified BoardGame.Common.Domain.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.GameParams as GameParams
import qualified BoardGame.Client.GameClient as Client
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import qualified BoardGame.Common.Domain.PieceGeneratorType as PieceGeneratorType
import qualified BoardGame.Common.Domain.TileSack as TileSack

dimension = 9
name = "John"
player = Player name
pieceGeneratorType = PieceGeneratorType.Cyclic
gameParams = GameParams dimension 12 "en" name pieceGeneratorType
gen = TileSack.mkDefaultPieceGen pieceGeneratorType
mkPiece = TileSack.pieceOf

main :: IO ()
main = do
  let baseUrl = BaseUrl Http "localhost" 6587 ""
  manager <- mkManager
  eitherMaybeUnit <- runExceptT (Client.addPlayer player manager baseUrl)
  print $ show eitherMaybeUnit

  -- TODO. Use do with state monad.
  (up0, gen') <- mkPiece gen 'B'
  (up1, gen'') <- mkPiece gen 'E'
  (up2, gen''') <- mkPiece gen 'T'
  let uPieces = [up0, up1, up2]

  (mp0, gen'''') <- mkPiece gen 'S'
  (mp1, gen''''') <- mkPiece gen 'E'
  (mp2, gen'''''') <- mkPiece gen 'Z'
  let mPieces = [mp0, mp1, mp2]

  -- uPieces <- sequence [mkPiece 'B', mkPiece 'E', mkPiece 'T'] -- Allow the word 'BET'
  -- mPieces <- sequence [mkPiece 'S', mkPiece 'T', mkPiece 'Z'] -- Allow the word 'SET' across.

  eitherGameDto <- runExceptT (Client.startGame (StartGameRequest gameParams [] uPieces mPieces) manager baseUrl)
  print $ show eitherGameDto
  print ""

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings
