package com.bolour.util.scala.common

sealed abstract class BlackWhite[T] {
  def isWhite: Boolean
  def isBlack: Boolean
  def isEmpty: Boolean
  def hasValue: Boolean
}

case class Black[T]() extends BlackWhite[T] {
  override def isWhite = false
  override def isBlack = true
  override def isEmpty = false
  override def hasValue = false
}
case class White[T](value: Option[T]) extends BlackWhite[T] {
  override def isWhite = true
  override def isBlack = false
  override def isEmpty = value.isEmpty
  override def hasValue = value.isDefined
}

object BlackWhite {
  def fromWhite[T](blackWhite: BlackWhite[T]): Option[T] = {
    blackWhite match {
      case Black() => None
      case White(opt) => opt
    }
  }

  def fromWhites[T](line: List[BlackWhite[T]], begin: Int, end: Int): List[Option[T]] =
    (begin to end).toList map { i => BlackWhite.fromWhite(line(i))}

}