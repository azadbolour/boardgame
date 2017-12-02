/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.util.BasicUtil.{ID, stringId}

case class Player(id: ID, name: String)

object Player {
  def apply(name: String): Player = Player(stringId, name)
}
