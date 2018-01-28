package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

import scala.util.{Failure, Success}

// Note. This test is flaky. Depends on random piece generation.

class PieceProviderSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)
  val dimension = 15
  val trayCapacity = 15

  "piece provider" should "be depleted of taken tiles" in {
    val provider = RandomPieceProvider(dimension)
    val RandomPieceProvider(initialContents, contents) = provider
    initialContents.length shouldBe 151
    contents.length shouldBe 151

    for {
      (RandomPieceProvider(initialContents, contents), pieces) <- provider.takeAvailableTiles(trayCapacity)
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

  "piece provider" should "produce tiles with distinct ids" in {

    val provider = RandomPieceProvider(15)

    val result = for {
      (RandomPieceProvider(initialContents, contents), pieces) <- provider.takeAvailableTiles(trayCapacity)
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
