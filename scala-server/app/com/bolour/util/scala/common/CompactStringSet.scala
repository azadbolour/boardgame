/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.util.scala.common

import scala.collection.mutable

/**
  * Space-efficient implementation of a set of small strings.
  * Hashes strings into compactly packed buckets.
  * Not time-efficient for inserting collections. Needs to be parallelized.
  * A failed attempt at reducing the memory footprint of dictionary masked words.
  */
class CompactStringSet {

  import CompactStringSet._

  val buckets = mutable.Map[Int, String]()

  def insert(elem: String): Unit = {
    val index = hash(elem)
    val bucket = buckets.get(index)
    val bucketPlus = bucket match {
      case None => elem
      case Some(elems) => pack(elems, elem)
    }
    buckets(index) = bucketPlus
  }

  def contains(elem: String): Boolean = {
    val index = hash(elem)
    val bucket = buckets.get(index)
    bucket match {
      case None => false
      case Some(elems) => unpack(elems).contains(elem)
    }
  }

  def ++(elems: Iterator[String]): Unit = elems.foreach {elem => insert(elem)}
  def ++(elems: java.util.stream.Stream[String]): Unit = elems.forEach {elem => insert(elem)}

  private def hash(string: String): Int = string.hashCode & hashMask

  override def toString = buckets.toString

}

object CompactStringSet {
  // TODO. Hash bits and delimiter should be instance parameters.
  val hashMask = 0x8FFFF  // 589823
  val delimiterChar = '\u0000'
  val delimiter = delimiterChar.toString

  def pack(packedStrings: String, elem: String): String =
    packedStrings ++ delimiter ++ elem

  def unpack(packedStrings: String): List[String] = packedStrings.split(delimiter).toList

  def apply(iterator: Iterator[String]): CompactStringSet = {
    val set = new CompactStringSet()
    set ++ iterator
    set
  }

  def apply(stream: java.util.stream.Stream[String]): CompactStringSet = {
    val set = new CompactStringSet()
    set ++ stream
    set
  }

  def apply(list: List[String]): CompactStringSet = CompactStringSet(list.iterator)
}
