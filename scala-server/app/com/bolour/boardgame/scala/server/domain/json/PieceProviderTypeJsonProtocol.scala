package com.bolour.boardgame.scala.server.domain.json

import com.bolour.boardgame.scala.common.domain.PieceProviderType
import com.bolour.boardgame.scala.common.domain.PieceProviderType.PieceProviderType
import com.bolour.boardgame.scala.server.domain.json.JsonUtil._
import org.slf4j.LoggerFactory
import spray.json.{DefaultJsonProtocol, JsString, JsValue, RootJsonFormat, deserializationError}

object PieceProviderTypeJsonProtocol extends DefaultJsonProtocol {

  val logger = LoggerFactory.getLogger(this.getClass)

  implicit object PieceProviderTypeFormat extends RootJsonFormat[PieceProviderType] {
    override def write(pieceProviderType: PieceProviderType): JsValue = JsString(pieceProviderType.toString)

    override def read(json: JsValue): PieceProviderType = {
      val asString = unwrapQuotedJsonString(json)
      try {
        PieceProviderType.fromString(asString)
      } catch {
        case _: Exception => deserializationError("PieceProviderType expected")
      }
    }
  }
}
