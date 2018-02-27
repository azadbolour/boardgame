package com.bolour.util

sealed abstract class BlackWhite[T]

case class Black[T]() extends BlackWhite[T]
case class White[T](value: Option[T]) extends BlackWhite[T]

object BlackWhite {
  def isJustWhite[T](blackWhite: BlackWhite[T]): Boolean = {
    blackWhite match {
      case Black() => false
      case White(opt) => opt.isDefined
    }
  }

  def fromWhite[T](blackWhite: BlackWhite[T]): Option[T] = {
    blackWhite match {
      case Black() => None
      case White(opt) => opt
    }
  }
}