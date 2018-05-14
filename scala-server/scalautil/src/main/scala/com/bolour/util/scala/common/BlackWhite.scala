/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.util.scala.common

/**
  * Abstraction for representing a value that may be disabled/inactive (black),
  * or enabled/active (white) but may be empty. Makes a clear distinction
  * between inactive and empty. Empty may be filled. Inactive may not.
  */
sealed abstract class BlackWhite[T] {
  def isWhite: Boolean
  def isBlack: Boolean
  def isEmpty: Boolean
  def hasValue: Boolean
  def fromWhite: Option[T]
  def map[R](f: T => R): BlackWhite[R]
  def toValueWithDefaults(blackDefault: Char, whiteDefault: Char): Char
}

/**
  * An inactive/disabled object, e.g. a black square in a crossword puzzle.
  */
case class Black[T]() extends BlackWhite[T] {
  override def isWhite = false
  override def isBlack = true
  override def isEmpty = false
  override def hasValue = false
  override def fromWhite = None
  override def map[R](f: T => R) = Black[R]
  def toValueWithDefaults(blackDefault: Char, whiteDefault: Char) = blackDefault
}

/**
  * An enabled/active object that may nevertheless not have any value,
  * e.g., a white square in a crossword puzzle.
  */
case class White[T](value: Option[T]) extends BlackWhite[T] {
  override def isWhite = true
  override def isBlack = false
  override def isEmpty = value.isEmpty
  override def hasValue = value.isDefined
  override def fromWhite = value
  override def map[R](f: T => R) =
    value match {
      case None => White(None)
      case Some(value) => White(Some(f(value)))
    }
  def toValueWithDefaults(blackDefault: Char, whiteDefault: Char) = whiteDefault

}

object BlackWhite {

  def fromWhites[T](line: List[BlackWhite[T]], begin: Int, end: Int): List[Option[T]] =
    (begin to end).toList map { i => line(i).fromWhite}

}