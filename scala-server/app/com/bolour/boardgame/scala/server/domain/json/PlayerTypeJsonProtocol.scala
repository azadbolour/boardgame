package com.bolour.boardgame.scala.server.domain.json

import spray.json.{DefaultJsonProtocol, JsString, JsValue, RootJsonFormat, deserializationError}
import com.bolour.boardgame.scala.common.domain.PlayerType._
import com.bolour.boardgame.scala.server.domain.json.JsonUtil.unwrapQuotedJsonString

object PlayerTypeJsonProtocol extends DefaultJsonProtocol {

  // Use Pascal-case constants used in cases.
  private val UserPlayerString = "User"
  private val MachinePlayerString = "Machine"

  implicit object PlayerTypeFormat extends RootJsonFormat[PlayerType] {
    override def write(playerType: PlayerType): JsValue = playerType match {
      case UserPlayer => JsString(UserPlayerString)
      case MachinePlayer => JsString(MachinePlayerString)
    }

    override def read(json: JsValue): PlayerType = {
      val playerString = unwrapQuotedJsonString(json)
      playerString match {
        case UserPlayerString => UserPlayer
        case MachinePlayerString => MachinePlayer
        case _ => deserializationError("PlayerType expected")
      }
    }

  }
}
