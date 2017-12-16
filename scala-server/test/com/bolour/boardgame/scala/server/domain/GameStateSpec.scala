package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{GameParams, PieceGeneratorType}
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

import scala.util.{Failure, Success}

// TODO. This test is flaky - depends on random piece generation.

class GameStateSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)
  val dimension = 15
  val trayCapacity = 15
  val genType = PieceGeneratorType.Random
  val name = "John"

  "initial game state" should "not have duplicate piece ids" in {
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

}
