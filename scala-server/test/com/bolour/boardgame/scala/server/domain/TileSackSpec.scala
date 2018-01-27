package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

import scala.util.{Failure, Success}

// Note. This test is flaky. Depends on random piece generation.

class TileSackSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)
  val dimension = 15
  val trayCapacity = 15

  "tile sack" should "be depleted of taken tiles" in {
    val sack = RandomTileSack(dimension)
    val RandomTileSack(initialContents, contents) = sack
    initialContents.length shouldBe 151
    contents.length shouldBe 151

    for {
      (RandomTileSack(initialContents, contents), pieces) <- sack.takeAvailableTiles(trayCapacity)
      _ = initialContents.length shouldBe Piece.maxDistribution
      _ = contents.length shouldBe Piece.maxDistribution - trayCapacity
      _ = pieces.length shouldBe trayCapacity
      pieceIds = pieces map { p => p.id }
      contentIds = contents map { p => p.id }
      initialContentIds = initialContents map { p => p.id }
      _ = pieceIds intersect contentIds shouldBe Nil
      _ = (pieceIds union contentIds).toSet shouldBe initialContentIds.toSet
    } yield 1
  }

  "tile sack" should "produce tiles with distinct ids" in {
//    def repetitions(frequencies: Map[Char, Int])(ch: Char): Int = 1
//
//    val initialPieces = RandomTileSack.generatePieces(Piece.frequencyMap, repetitions)
//    // initialPieces.foreach { p => logger.info(s"${p}") }
//
//    val ids = initialPieces map { p => p.id }
//    ids.distinct.length shouldBe ids.length
//
//    val sack = RandomTileSack(initialPieces)

    val sack = RandomTileSack(15)

    val result = for {
      (RandomTileSack(initialContents, contents), pieces) <- sack.takeAvailableTiles(trayCapacity)
      pieceIds = (pieces map { p => p.id }).distinct
      _ = pieceIds.length shouldBe pieces.length
      contentIds = (contents map { p => p.id }).distinct
      _ = contentIds.length shouldBe contents.length
      _ = contentIds.length + pieceIds.length shouldBe initialContents.length
    } yield ()

    result match {
      case Success(_) => ()
      case Failure(ex) => fail(ex)
    }
  }
}
