package com.bolour.plane.scala.domain

import com.bolour.plane.scala.domain.Axis.{Axis, X, Y}
import com.bolour.util.scala.common.{Black, BlackWhite}

/**
  * An active line segment of a grid - a line segment does not contain
  * inactive (black) points.
  * @param axis The direction of the line segment (X, Y).
  * @param lineNumber The index of the enclosing grid line (row for X, col for Y).
  * @param begin The starting position of the segment in its line.
  * @param end The ending position of the segment in its line.
  * @param segment The list of values (or no-values) of the segment.
  * @tparam T The type of the contained value if any.
  */
case class LineSegment[T](axis: Axis, lineNumber: Int, begin: Int, end: Int, segment: List[Option[T]]) {

  def row(offset: Int): Int = axis match {
    case X => lineNumber
    case Y => begin + offset
  }

  def column(offset: Int): Int = axis match {
    case X => begin + offset
    case Y => lineNumber
  }

  def point(offset: Int) = Point(row(offset), column(offset))
}

object LineSegment {

  def segmentsInLine[T](axis: Axis, lineNumber: Int, line: List[BlackWhite[T]]): List[LineSegment[T]] = {
    def black(i: Int) = i < 0 || i >= line.length || line(i) == Black()
    def white(i: Int) = !black(i)
    def isBeginSegment(i: Int) = white(i) && black(i - 1)
    def isEndSegment(i: Int) = white(i) && black(i + 1)

    val indices = line.indices.toList
    val begins = indices filter isBeginSegment
    val ends = indices filter isEndSegment
    val liveIntervals = begins zip ends

    val segments = for {
      (intervalBegin, intervalEnd) <- liveIntervals
      begin <- intervalBegin to intervalEnd
      end <- begin to intervalEnd
      segment = BlackWhite.fromWhites(line, begin, end)
    } yield LineSegment(axis, lineNumber, begin, end, segment)
    segments
  }

}
