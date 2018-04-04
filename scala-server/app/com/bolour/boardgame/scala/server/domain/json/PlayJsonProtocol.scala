package com.bolour.boardgame.scala.server.domain.json

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece}
import com.bolour.boardgame.scala.server.domain.{Play, SwapPlay, WordPlay}
import com.bolour.plane.scala.domain.Point
import org.slf4j.LoggerFactory
import spray.json._

object PlayJsonProtocol extends DefaultJsonProtocol {

  val logger = LoggerFactory.getLogger(this.getClass)

  import com.bolour.boardgame.scala.server.domain.json.PlayerTypeJsonProtocol._
  import com.bolour.boardgame.scala.server.domain.json.PlayTypeJsonProtocol._

  implicit val pieceFormat = jsonFormat2(Piece.apply)
  implicit val pointFormat = jsonFormat2(Point)
  implicit val playPieceFormat = jsonFormat3(PlayPiece)
  implicit val wordPlayFormat = jsonFormat6(WordPlay)
  implicit val swapPlayFormat = jsonFormat6(SwapPlay)

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
