package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Axis.Axis
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

  def mkPlayPieces(startingPoint: Point, axis: Axis, length: Int, pieces: Vector[Piece]): List[PlayPiece] = {
    val row = startingPoint.row
    val col = startingPoint.col
    val vector = pieces.take(length) zip (0 until length) map {
      case (piece, i) =>
        val playPoint = axis match {
          case Axis.X => Point(row, col + i)
          case Axis.Y => Point(row + 1, col)
        }
        PlayPiece(piece, playPoint, true)
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
      playPieces1 = mkPlayPieces(Point(0, 0), Axis.X, dimension, gameState.trays(0).pieces)
      (gameState1, _) <- gameState.addPlay(UserPlayer, playPieces1)
      // (7, 7, 7, 5)

      playPieces2 = mkPlayPieces(Point(1, 0), Axis.X, dimension, gameState1.trays(0).pieces)
      (gameState2, _) <- gameState1.addPlay(UserPlayer, playPieces2)
      // (7, 7, 2, 10)
      _ = (gameState2.pieceGenerator.length < 5) shouldBe true

      playPieces3 = mkPlayPieces(Point(2, 0), Axis.X, dimension, gameState2.trays(0).pieces)
      (gameState3, replacements3) <- gameState2.addPlay(UserPlayer, playPieces3)
      // (4, 7, 0, 15)
      _ = gameState3.pieceGenerator.length shouldBe 0
      _ = replacements3.length shouldBe 2
      _ = gameState3.trays(0).pieces.length shouldBe 4

      playPieces4 = mkPlayPieces(Point(3, 0), Axis.X, 4, gameState3.trays(0).pieces)
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

  "play scores" should "be computed correctly" in {
    val dimension = 15
    val trayCapacity = 7

    val gameParams = GameParams(dimension, trayCapacity, "en", name, PieceGeneratorType.Cyclic)
    val game = Game(gameParams, "123")

    def pc(ch: Char): Piece = Piece(ch)

    // Plays wil yield:
    /*
                    2         5
        - - - - - - - - - - - - - - -
      6 - - - - - - - - E G I P T O -
      4 - - - - - C H U T N E E - - -
        - - - - - - R - - - - R - - -
      3 - - - - F A D E - - - U - - -
        - - - - - - W - - - - - - - -
        - - - - - - R - - - - - - - -
        - - - - - V E N D - - - - - -
     */

    val machinePlay1 = List(
      PlayPiece(pc('V'), Point(7, 5), true),
      PlayPiece(pc('E'), Point(7, 6), true),
      PlayPiece(pc('N'), Point(7, 7), true),
      PlayPiece(pc('D'), Point(7, 8), true),
    )

    val userPlay1 = List(
      PlayPiece(pc('H'), Point(2, 6), true),
      PlayPiece(pc('R'), Point(3, 6), true),
      PlayPiece(pc('D'), Point(4, 6), true),
      PlayPiece(pc('W'), Point(5, 6), true),
      PlayPiece(pc('R'), Point(6, 6), true),
      PlayPiece(pc('E'), Point(7, 6), false),
    )

    val machinePlay2 = List(
      PlayPiece(pc('F'), Point(4, 4), true),
      PlayPiece(pc('A'), Point(4, 5), true),
      PlayPiece(pc('D'), Point(4, 6), false),
      PlayPiece(pc('E'), Point(4, 7), true),
    )

    val userPlay2 = List(
      PlayPiece(pc('C'), Point(2, 5), true),
      PlayPiece(pc('H'), Point(2, 6), false),
      PlayPiece(pc('U'), Point(2, 7), true),
      PlayPiece(pc('T'), Point(2, 8), true),
      PlayPiece(pc('N'), Point(2, 9), true),
      PlayPiece(pc('E'), Point(2, 10), true),
      PlayPiece(pc('E'), Point(2, 11), true),
    )

    val machinePlay3 = List(
      PlayPiece(pc('P'), Point(1, 11), true),
      PlayPiece(pc('E'), Point(2, 11), false),
      PlayPiece(pc('R'), Point(3, 11), true),
      PlayPiece(pc('U'), Point(4, 11), true),
    )

    val userPlay3 = List(
      PlayPiece(pc('E'), Point(1, 8), true),
      PlayPiece(pc('G'), Point(1, 9), true),
      PlayPiece(pc('I'), Point(1, 10), true),
      PlayPiece(pc('P'), Point(1, 11), false),
      PlayPiece(pc('T'), Point(1, 12), true),
      PlayPiece(pc('O'), Point(1, 13), true),
    )

    val result = for {
      gameState <- GameState.mkGameState(game, List(), List(), List())

      (gameState1, _) <- gameState.addPlay(MachinePlayer, machinePlay1)
      machineScore1 = gameState1.miniState.lastPlayScore
      _ = machineScore1 shouldBe 16

      (gameState2, _) <- gameState1.addPlay(UserPlayer, userPlay1)
      userScore1 = gameState2.miniState.lastPlayScore
      _ = userScore1 shouldBe 18

      (gameState3, _) <- gameState2.addPlay(MachinePlayer, machinePlay2)
      machineScore2 = gameState3.miniState.lastPlayScore
      _ = machineScore2 shouldBe 16

      (gameState4, _) <- gameState3.addPlay(UserPlayer, userPlay2)
      userScore2 = gameState4.miniState.lastPlayScore
      _ = userScore2 shouldBe 13

      (gameState5, _) <- gameState4.addPlay(MachinePlayer, machinePlay3)
      machineScore3 = gameState5.miniState.lastPlayScore
      _ = machineScore3 shouldBe 12

      (gameState6, _) <- gameState5.addPlay(UserPlayer, userPlay3)
      userScore3 = gameState6.miniState.lastPlayScore
      egiptoScore = 2 * (1 + 3*2 + 1 + 3 + 1 + 1)
      etCrossScore = 1 + 1
      gnCrossScore = 3*2 + 1
      ieCrossScore = 1 + 1
      _ = userScore3 shouldBe egiptoScore + etCrossScore + gnCrossScore + ieCrossScore

    } yield ()

    result match {
      case Success(_) => ()
      case Failure(ex) => fail(ex)
    }
  }


}
