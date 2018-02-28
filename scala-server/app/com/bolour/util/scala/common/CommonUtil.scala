/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.util.scala.common

object CommonUtil {
  type ID = String

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

}
