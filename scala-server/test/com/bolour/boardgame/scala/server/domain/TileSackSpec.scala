package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class TileSackSpec extends FlatSpec with Matchers {

  val logger = LoggerFactory.getLogger(this.getClass)
  val dimension = 15
  val trayCapacity = 7

  val sack = RandomTileSack(dimension)

  "tile sack" should "be depleted of taken tiles" in {
    val RandomTileSack(initialContents, contents) = sack
    initialContents.length shouldBe Piece.maxDistribution
    contents.length shouldBe Piece.maxDistribution

    for {
      (RandomTileSack(initialContents, contents), pieces) <- sack.takeN(trayCapacity)
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
}
