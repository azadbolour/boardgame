/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package controllers

import javax.inject._

import play.api.mvc._

@Singleton
class IndexController @Inject() (cc: ControllerComponents) extends AbstractController(cc) {
  def index = Action {
    Ok(views.html.index())
  }
}
