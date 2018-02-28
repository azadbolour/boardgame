package com.bolour.boardgame.scala.server.domain

import java.util.UUID

import com.bolour.boardgame.scala.common.domain.{GridPiece, Piece}
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.Point
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

import scala.collection.immutable

class StripMatcher2Spec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val MaxMaskedLetters = 2

  // TODO. Move generic functions to a base class.
  def allTheSame[A, B](seq: IndexedSeq[A])(f: A => B): Boolean = {
    val l = seq.length
    if (l == 0) return true
    val first = f(seq(0))
    seq.forall { v => f(v) == first}
  }

  def mkTray(chars: String): Tray = Tray(chars.length, Vector(mkPieces(chars):_*))

  def mkInitialBoard(dimension: Int, word: String): Board = {
    val l = word.length
    val pieces = mkPieces(word)
    val center = dimension / 2
    val gridPieces = (center until (center + l)).map { col => GridPiece(pieces(col - center), Point(center, col))}
    Board(dimension, gridPieces.toList)
  }

  def mkPieces(chars: String) = {
    val l = chars.length
    (0 until l).map { i => Piece(chars(i), UUID.randomUUID().toString) }
  }

  "stripMatcher" should "match vertical after first horizontal move" in {
    val stripMatcher = new StripMatcher {
      override def tray = mkTray("ORGANIC");
      override def dictionary = WordDictionary(WordUtil.english, List("ORGANIC"), MaxMaskedLetters)
      override def board = mkInitialBoard(15, "CODER")
    }

    val playPieces = stripMatcher.bestMatch()
    playPieces.length shouldBe 7
    val vertical = allTheSame(playPieces.toIndexedSeq) (_.point.col)
    vertical shouldBe true
  }

}
