package com.bolour.boardgame.scala.common.domain
import com.bolour.boardgame.scala.common.domain.ScoreMultiplierType._

case class ScoreMultiplier(scoreMultiplierType: ScoreMultiplierType, factor: Int) {
  def isWordMultiplier: Boolean = (scoreMultiplierType == Letter)
}

object ScoreMultiplier {
  def noMultiplier() = ScoreMultiplier(None, 1)

  def letterMultiplier(factor: Int) = ScoreMultiplier(Letter, factor)

  def wordMultiplier(factor: Int) = ScoreMultiplier(Word, factor)
}
