module Main where

import Control.Monad.Except (runExceptT)

import Network.HTTP.Client (Manager, newManager, defaultManagerSettings)
import Servant.Client
-- import Servant.Common.BaseUrl()

import BoardGame.Common.Domain.PlayerDto (PlayerDto(PlayerDto))
import BoardGame.Common.Domain.Piece (Piece)
import BoardGame.Common.Domain.InitPieces (InitPieces(InitPieces))
import qualified BoardGame.Common.Domain.Piece as Piece
import Bolour.Plane.Domain.Point (Point(Point))
import qualified Bolour.Plane.Domain.Point as Point
import BoardGame.Common.Domain.GameParams (GameParams(GameParams))
import qualified BoardGame.Common.Domain.Piece as Piece
import qualified BoardGame.Common.Domain.GameParams as GameParams
import qualified BoardGame.Client.GameClient as Client
import BoardGame.Common.Message.StartGameRequest (StartGameRequest(StartGameRequest))
import qualified BoardGame.Common.Domain.PieceProviderType as PieceProviderType

dimension = 9
name = "John"
player = PlayerDto name
pieceGeneratorType = PieceProviderType.Cyclic
gameParams = GameParams dimension 12 "en" name pieceGeneratorType

mkPiece :: Char -> Int -> Piece
mkPiece letter id = Piece.Piece letter (show id)

main :: IO ()
main = do
  let baseUrl = BaseUrl Http "localhost" 6587 ""
  manager <- mkManager
  -- eitherMaybeUnit <- runExceptT (Client.addPlayer player manager baseUrl)
  eitherMaybeUnit <- runClientM (Client.addPlayer player) (mkClientEnv manager baseUrl)
  print $ show eitherMaybeUnit

  -- Ideally should get pieces from the server - since the server is the owner of the tile sack.
  -- We'll let that go for now.

  let uPieces = [mkPiece 'B' 1, mkPiece 'E' 2, mkPiece 'T' 3] -- Allow the word 'BET'
      mPieces = [mkPiece 'S' 4, mkPiece 'E' 5, mkPiece 'Z' 6] -- Allow the word 'SET' across.
      initPieces = InitPieces [] uPieces mPieces

  eitherGameDto <- runClientM (Client.startGame (StartGameRequest gameParams initPieces [])) (mkClientEnv manager baseUrl)
  print $ show eitherGameDto
  print ""

mkManager :: IO Manager
mkManager = newManager defaultManagerSettings
