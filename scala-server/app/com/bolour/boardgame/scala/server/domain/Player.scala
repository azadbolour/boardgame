/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */
package com.bolour.boardgame.scala.server.domain

import com.bolour.util.scala.common.CommonUtil.{ID, Email}
import com.bolour.util.scala.server.BasicServerUtil.{stringId}

/**
  * Player.
  *
  * @param id The unique identifier of the player in the board game database.
  * @param userId The unique identifier of the player as a user
  *                       in the authentication provider's system.
  * @param name The name of the user. For maximum security we just use the first name.
  * @param email The player's email.
  *              The email is the "natural key" of the user in the boardgame system.
  */
case class Player(id: ID, userId: String, name: String, email: Email)

