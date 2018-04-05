package com.bolour.boardgame.scala.server.domain

import com.bolour.plane.scala.domain.Point

case class PlayEffect(play: Play, deadPoints: List[Point])
