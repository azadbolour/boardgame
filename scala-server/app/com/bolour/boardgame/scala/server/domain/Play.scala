package com.bolour.boardgame.scala.server.domain

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece, PlayerType}
import com.bolour.boardgame.scala.common.domain.PlayerType.PlayerType
import com.bolour.plane.scala.domain.Point
import spray.json._

sealed abstract class PlayType
object WordPlayType extends PlayType
object SwapPlayType extends PlayType

sealed abstract class Play(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int]) {
}

case class WordPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  playPieces: List[PlayPiece], replacementPieces: List[Piece]) extends Play(playType, playNumber, playerType, scores)

case class SwapPlay(playType: PlayType, playNumber: Int, playerType: PlayerType, scores: List[Int],
  swappedPiece: Piece, newPiece: Piece) extends Play(playType, playNumber, playerType, scores)

// TODO. Move JSON conversions to separate classes for each class.

object PlayerTypeJsonProtocol extends DefaultJsonProtocol {

  implicit object PlayerTypeFormat extends RootJsonFormat[PlayerType] {
    override def write(playerType: PlayerType): JsValue = ???

    override def read(json: JsValue): PlayerType = ???
  }
}

object PlayTypeJsonProtocol extends DefaultJsonProtocol {
  private val wordPlayTypeString = "WordPlayType"
  private val swapPlayTypeString = "SwapPlayType"

  implicit object PlayTypeFormat extends RootJsonFormat[PlayType] {
    override def write(playType: PlayType): JsValue = playType match {
      case WordPlayType => JsString(wordPlayTypeString)
      case SwapPlayType => JsString(swapPlayTypeString)
    }

    override def read(json: JsValue): PlayType =
      json.convertTo[String] match {
        case `wordPlayTypeString` => WordPlayType
        case `swapPlayTypeString` => SwapPlayType
        case _ => deserializationError("PlayType expected")
      }
  }
}

object PlayJsonProtocol extends DefaultJsonProtocol {

  import PlayerTypeJsonProtocol._
  import PlayTypeJsonProtocol._

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
      json.asJsObject.fields("playType") match {
        case JsString("WordPlay") => json.convertTo[WordPlay]
        case JsString("SwapPlay") => json.convertTo[SwapPlay]
        case _ => deserializationError("Play expected")
      }
    }
  }
}
