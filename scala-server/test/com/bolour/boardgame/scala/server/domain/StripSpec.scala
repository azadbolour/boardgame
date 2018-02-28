package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.server.domain.Strip._
import com.bolour.util.scala.common.domain.Axis
import org.scalatest.{FlatSpec, Matchers}

class StripSpec extends FlatSpec with Matchers {

  "live strips" should "be computed correctly" in {
    val liveStrips = liveStripsInLine(Axis.X, 2, "-ABC---DE-F-GH")
    liveStrips should contain (Strip(Axis.X, 2, 2, 3, "BC"))
    liveStrips should contain (Strip(Axis.X, 2, 12, 13, "GH"))
    liveStrips should contain (Strip(Axis.X, 2, 10, 10, "F"))
  }

  "all live strips" should "be computed" in {
    val lines = List(
      " AB-  C -- DEF",
      "G- HI--   J -K"
    )
    val liveStrips = allLiveStrips(Axis.X, lines)
    liveStrips should contain (Strip(Axis.X, 0, 0, 1, " A"))
    liveStrips should contain (Strip(Axis.X, 1, 9, 11, " J "))
  }
}
