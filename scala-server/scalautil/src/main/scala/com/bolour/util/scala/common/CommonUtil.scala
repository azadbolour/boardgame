/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.util.scala.common

object CommonUtil {
  // TODO. Use Scala value class.
  type ID = String
  case class Email(val email: String) extends AnyVal

  def javaListToScala[T](source: java.util.List[T]): List[T] = {
    // TODO. Scala syntax for inlining the next two lines as a parameter to fill??
    val it = source.iterator()
    def nextElement: T = it.next()
    source match {
      case null => List()
      case _ => List.fill(source.size()) { nextElement }
    }
  }

  def inverseMultiValuedMapping[A, B](f: A => List[B])(as: List[A]): Map[B, List[A]] = {
    def pairMaker(a: A): List[(A, B)] = f(a) map {b => (a, b)}
    val pairs = as flatMap pairMaker
    pairs.groupBy(_._2).mapValues(_ map {case (a, b) => a})
  }

  def catOptions[T](options: List[Option[T]]): List[T] = {
    def folder(opt: Option[T], list: List[T]): List[T] = {
      opt match {
        case None => list
        case Some(t) => t :: list
      }
    }
    options.foldRight(List[T]())(folder)
  }

}
