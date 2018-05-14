/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.common.domain

object PlayerType {

  sealed abstract class PlayerType

  object UserPlayer extends PlayerType
  object MachinePlayer extends PlayerType

  def playerIndex(playerType: PlayerType): Int = playerType match {
    case UserPlayer => 0
    case MachinePlayer => 1
  }

  def nextPlayerType(playerType: PlayerType): PlayerType =
    playerType match {
      case UserPlayer => MachinePlayer
      case MachinePlayer => UserPlayer
    }
}

