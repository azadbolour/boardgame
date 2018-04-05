package com.bolour.boardgame.scala.server.domain.json

import com.bolour.boardgame.scala.common.domain.{Piece, PlayPiece}
import com.bolour.boardgame.scala.server.domain.{PlayEffect, SwapPlay, WordPlay}
import com.bolour.plane.scala.domain.Point
import spray.json._

object CaseClassFormats extends DefaultJsonProtocol {

  import com.bolour.boardgame.scala.server.domain.json.PlayerTypeJsonProtocol.PlayerTypeFormat
  import com.bolour.boardgame.scala.server.domain.json.PlayTypeJsonProtocol.PlayTypeFormat
  import com.bolour.boardgame.scala.server.domain.json.PlayJsonProtocol.PlayJsonFormat

  implicit val pieceFormat = jsonFormat2(Piece.apply)
  implicit val pointFormat = jsonFormat2(Point)
  implicit val playPieceFormat = jsonFormat3(PlayPiece)

  implicit val wordPlayFormat = jsonFormat6(WordPlay)
  implicit val swapPlayFormat = jsonFormat6(SwapPlay)

  implicit val playEffectFormat = jsonFormat2(PlayEffect)

}
