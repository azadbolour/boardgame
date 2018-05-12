/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *    https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package controllers

import javax.inject._

import org.slf4j.LoggerFactory
import play.api.mvc._

@Singleton
class IndexController @Inject() (assets: Assets, cc: ControllerComponents) extends AbstractController(cc) {

  val logger = LoggerFactory.getLogger(this.getClass)

  def index: Action[AnyContent] = {
    assets.at("index.html")
  }
}
