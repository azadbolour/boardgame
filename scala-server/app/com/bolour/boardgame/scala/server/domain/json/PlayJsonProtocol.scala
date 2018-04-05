package com.bolour.boardgame.scala.server.domain.json

import org.slf4j.LoggerFactory
import spray.json._

import com.bolour.boardgame.scala.server.domain.{Play, SwapPlay, WordPlay}
import com.bolour.boardgame.scala.server.domain.json.CaseClassFormats._

object PlayJsonProtocol extends DefaultJsonProtocol {

  val logger = LoggerFactory.getLogger(this.getClass)

  implicit object PlayJsonFormat extends RootJsonFormat[Play] {

    override def write(play: Play): JsValue = play match {
      case wp: WordPlay => wp.toJson
      case sp: SwapPlay => sp.toJson
    }

    // TODO. How is PlayType serialized?
    override def read(json: JsValue): Play = {
      val playType = json.asJsObject.fields("playType")
      playType match {
        case JsString(PlayTypeJsonProtocol.WordPlayTypeString) => json.convertTo[WordPlay]
        case JsString(PlayTypeJsonProtocol.SwapPlayTypeString) => json.convertTo[SwapPlay]
        case _ => deserializationError("Play expected")
      }
    }
  }
}
