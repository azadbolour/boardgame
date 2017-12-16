package com.bolour.boardgame.scala.common.domain

case class StopInfo(
  successivePasses: Int,
  maxSuccessivePasses: Int,
  isSackEmpty: Boolean,
  isUserTrayEmpty: Boolean,
  isMachineTrayEmpty: Boolean
) {

}
