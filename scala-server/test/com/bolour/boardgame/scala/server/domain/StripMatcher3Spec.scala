package com.bolour.boardgame.scala.server.domain

import java.util.UUID

import com.bolour.boardgame.scala.common.domain.{PiecePoint, Piece}
import com.bolour.boardgame.scala.server.util.WordUtil
import com.bolour.language.scala.domain.WordDictionary
import com.bolour.plane.scala.domain.{Axis, Point}
import org.scalatest.{FlatSpec, Matchers}
import org.slf4j.LoggerFactory

class StripMatcher3Spec extends FlatSpec with Matchers { self =>
  val logger = LoggerFactory.getLogger(this.getClass)

  val dimension = 15
  val center = dimension / 2
  val MaxMaskedLetters = 2

  // TODO. Move generic functions to a base class.
  def allTheSame[A, B](seq: IndexedSeq[A])(f: A => B): Boolean = {
    val l = seq.length
    if (l == 0) return true
    val first = f(seq(0))
    seq.forall { v => f(v) == first}
  }

  def mkTray(chars: String): Tray = Tray(chars.length, Vector(mkPieces(chars):_*))

  def mkInitialBoard(word: String): Board = {
    val l = word.length
    val pieces = mkPieces(word)
    val gridPieces = (center until (center + l)).map { col => PiecePoint(pieces(col - center), Point(center, col))}
    Board(dimension, gridPieces.toList)
  }

  def mkPieces(chars: String) = {
    val l = chars.length
    (0 until l).map { i => Piece(chars(i), UUID.randomUUID().toString) }
  }

  "stripMatcher" should "find cross words" in {
    val crossGridPiece = PiecePoint(Piece('T', UUID.randomUUID().toString), Point(center - 1, center + 1))
    val stripMatcher = new StripMatcher {
      override def tray = mkTray("ORGANIC");
      val words = List("ORGANIC")
      val maskedWords = WordDictionary.mkMaskedWords(words, MaxMaskedLetters)
      override def dictionary = WordDictionary(WordUtil.english, words, maskedWords, MaxMaskedLetters)
      override def board = mkInitialBoard("CODER").setPiecePoints(List(crossGridPiece))
    }

    // trying for
    //
    // O
    // R
    // G
    // A
    // N
    // I T
    // C O D E R

    // T is a cross point when ORGANIC is played against CODER

    val crossWordFinder = new CrossWordFinder(stripMatcher.board)
    val crossChars = crossWordFinder.findCrossingWord(Point(center - 1, center), 'I', Axis.X)
    crossChars shouldBe Some("IT")

    // TODO. Reinstate.
    val playStrip = Strip(Axis.Y, center, center - 6, center, "      C")
    stripMatcher.crossings(playStrip, "ORGANIC") shouldBe List("IT")

  }

}
