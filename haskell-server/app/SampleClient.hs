module Main where

import Control.Monad.Except (runExceptT)

import Network.HTTP.Client (Manager, newManager, defaultManagerSettings)
import Servant.Client
import Servant.Common.BaseUrl()

import BoardGame.Common.Domain.Player (Player(Player))
import BoardGame.Common.Domain.Piece (Piece)
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Grid.Point (Point(Point))
import qualified Bolour.Grid.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.GameParams as GameParams
import qualified BoardGame.Client.GameClient as Client
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

dimension = 9
name = "John"
player = Player name
pieceGeneratorType = PieceProviderType.Cyclic
gameParams = GameParams dimension 12 "en" name pieceGeneratorType

mkPiece = Piece.mkPiece

main :: IO ()
main = do
  let baseUrl = BaseUrl Http "localhost" 6587 ""
  manager <- mkManager
  eitherMaybeUnit <- runExceptT (Client.addPlayer player manager baseUrl)
  print $ show eitherMaybeUnit

  -- Ideally should get pieces from the server - since the server is the owner of the tile sack.
  -- We'll let that go for now.

  uPieces <- sequence [mkPiece 'B', mkPiece 'E', mkPiece 'T'] -- Allow the word 'BET'
  mPieces <- sequence [mkPiece 'S', mkPiece 'E', mkPiece 'Z'] -- Allow the word 'SET' across.

  eitherGameDto <- runExceptT (Client.startGame (StartGameRequest gameParams [] uPieces mPieces []) manager baseUrl)
  print $ show eitherGameDto
  print ""

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings
