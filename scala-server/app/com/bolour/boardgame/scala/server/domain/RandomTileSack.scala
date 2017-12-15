package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.Piece
import com.bolour.util.BasicUtil

import scala.util.Try

case class RandomTileSack(initialContents: Vector[Piece], contents: Vector[Piece]) extends TileSack {

  override def isEmpty = contents.isEmpty

  def length = contents.length

  def take(): Try[(RandomTileSack, Piece)] = Try {
    if (contents.isEmpty)
      throw new IllegalArgumentException(s"attempt to take a random piece from empty sack")
    val index = (Math.random() * contents.length).toInt
    val piece = contents(index)
    val rest = contents.patch(index, Nil, 1)
    (RandomTileSack(initialContents, rest), piece)
  }

  override def swapPieces(swapped: List[Piece]): Try[(RandomTileSack, List[Piece])] = Try {
    val existing = swapped intersect contents
    if (existing.nonEmpty)
      throw new IllegalArgumentException(s"attempt to swap existing piece(s) - ${existing}")

    val nonExistent = swapped diff initialContents
    if (nonExistent.nonEmpty) // TODO. Use GameException.
      throw new IllegalArgumentException(s"attempt to swap non-existent piece(s) - ${nonExistent}")

    val n = swapped.length

    if (n >= contents.length)
      throw new IllegalArgumentException(s"attempt to swap more pieces (${n}) than exist in tile sack (${contents.length})")

    val (restContent, randomPieces) = BasicUtil.giveRandomElements((contents, Vector()), n)
    val replacedContent = restContent ++ swapped
    (RandomTileSack(initialContents, replacedContent), randomPieces.toList)
  }
}

object RandomTileSack {

  def mkInitialTileSack(dimension: Int): RandomTileSack = {
    val pieces = mkInitialContents(dimension)
    RandomTileSack(pieces, pieces)
  }

  /**
    * Put together the initial contents of a tile sack for any dimension.
    *
    * The letter frequencies for a 15x15 board are provided in Piece.frequencyMap.
    * The frequencies for a different dimension are computed by scaling the 15x15
    * frequencies based on board area.
    */
  def mkInitialContents(dimension: Int): Vector[Piece] = {
    val frequenciesFor15Board = Piece.frequencyMap

    val area15 = (15 * 15).toFloat
    val area = (dimension * dimension).toFloat
    val factor = area/area15

    /**
      * Scale the frequency of a letter making sure each letter
      * has at least one instance in the sack.
      */
    def repeats(ch: Char): Int =
      Math.round(frequenciesFor15Board(ch) * factor).min(1)

    var id = -1
    val pieces = frequenciesFor15Board.toList flatMap {
      case (ch, _) => (0 until repeats(ch)).map { _ =>
        id += 1
        Piece(ch, id.toString)
      }
    }
    pieces.toVector
  }
}
