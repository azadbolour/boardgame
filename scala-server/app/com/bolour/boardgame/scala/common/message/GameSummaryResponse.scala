package com.bolour.boardgame.scala.common.message

import com.bolour.boardgame.scala.common.domain.StopInfo

/**
  * Summary of game reported to clients after the last play.
  *
  * @param stopInfo Data about why the last play was reached.
  * @param endOfPlayScore The additional scores based on state of trays when the game stopped.
  * @param totalScore The final game score including play scores and the end of play scores.
  */
case class GameSummaryResponse(stopInfo: StopInfo, endOfPlayScore: List[Int], totalScore: List[Int])
