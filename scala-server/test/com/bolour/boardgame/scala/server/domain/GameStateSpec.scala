package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain._
import com.bolour.boardgame.scala.common.domain.PlayerType._
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

import scala.util.{Failure, Success}

// TODO. This test is flaky - depends on random piece generation.

class GameStateSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)
  val genType = PieceGeneratorType.Random
  val name = "John"

  def mkPlayPieces(startingPoint: Point, length: Int, pieces: Vector[Piece]): List[PlayPiece] = {
    val row = startingPoint.row
    val col = startingPoint.col
    val vector = pieces.take(length) zip (0 until length) map {
      case (piece, i) => PlayPiece(piece, Point(row, col + i), true)
    }
    vector.toList
  }

  "initial game state" should "not have duplicate piece ids" in {
    val dimension = 15
    val trayCapacity = 15
    val gameParams = GameParams(dimension, trayCapacity, "en", name, genType)
    val game = Game(gameParams, "123")
    val result = for {
      gameState <- GameState.mkGameState(game, List(), List(), List())
      _ <- gameState.sanityCheck
    } yield ()

    result match {
      case Success(_) => ()
      case Failure(ex) => fail(ex)
    }
  }

  "tray" should "be replenished to the extent possible" in {
    val dimension = 5
    val trayCapacity = 7

    val gameParams = GameParams(dimension, trayCapacity, "en", name, genType)
    val game = Game(gameParams, "123")
    val result = for {
      gameState <- GameState.mkGameState(game, List(), List(), List())
      _ = (gameState.pieceGenerator.length < 15) shouldBe true
      // (7, 7, 12, 0)
      playPieces1 = mkPlayPieces(Point(0, 0), dimension, gameState.trays(0).pieces)
      (gameState1, _) <- gameState.addPlay(UserPlayer, playPieces1)
      // (7, 7, 7, 5)

      playPieces2 = mkPlayPieces(Point(1, 0), dimension, gameState1.trays(0).pieces)
      (gameState2, _) <- gameState1.addPlay(UserPlayer, playPieces2)
      // (7, 7, 2, 10)
      _ = (gameState2.pieceGenerator.length < 5) shouldBe true

      playPieces3 = mkPlayPieces(Point(2, 0), dimension, gameState2.trays(0).pieces)
      (gameState3, replacements3) <- gameState2.addPlay(UserPlayer, playPieces3)
      // (4, 7, 0, 15)
      _ = gameState3.pieceGenerator.length shouldBe 0
      _ = replacements3.length shouldBe 2
      _ = gameState3.trays(0).pieces.length shouldBe 4

      playPieces4 = mkPlayPieces(Point(3, 0), 4, gameState3.trays(0).pieces)
      (gameState4, replacements4) <- gameState3.addPlay(UserPlayer, playPieces4)
      // (0, 7, 0, 19)
      _ = gameState4.pieceGenerator.length shouldBe 0
      _ = replacements4.length shouldBe 0

    } yield ()

    result match {
      case Success(_) => ()
      case Failure(ex) => fail(ex)
    }

  }

}
