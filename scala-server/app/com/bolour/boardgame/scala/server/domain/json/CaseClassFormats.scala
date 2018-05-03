package com.bolour.boardgame.scala.server.domain.json

import com.bolour.boardgame.scala.common.domain.{Piece, PiecePoint, PlayPiece}
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.service.GameData
import com.bolour.plane.scala.domain.Point
import com.bolour.util.scala.common.VersionStamped
import spray.json._

object CaseClassFormats extends DefaultJsonProtocol {

  import com.bolour.boardgame.scala.server.domain.json.PlayerTypeJsonProtocol.PlayerTypeFormat
  import com.bolour.boardgame.scala.server.domain.json.PlayTypeJsonProtocol.PlayTypeFormat
  import com.bolour.boardgame.scala.server.domain.json.PieceProviderTypeJsonProtocol.PieceProviderTypeFormat
  import com.bolour.boardgame.scala.server.domain.json.InstantJsonProtocol.InstantFormat
  import com.bolour.boardgame.scala.server.domain.json.PlayJsonProtocol.PlayJsonFormat

  implicit val pieceFormat = jsonFormat2(Piece.apply)
  implicit val pointFormat = jsonFormat2(Point)
  implicit val piecePointFormat = jsonFormat2(PiecePoint)
  implicit val playPieceFormat = jsonFormat3(PlayPiece)

  implicit val wordPlayFormat = jsonFormat7(WordPlay)
  implicit val swapPlayFormat = jsonFormat6(SwapPlay)

  implicit def gameBaseFormat = jsonFormat12(GameBase.apply)
  implicit def gameTransitionsFormat = jsonFormat2(GameData)

  implicit def versionedGameTransitionFormat = jsonFormat2(VersionStamped[GameData])

  implicit val playerFormat = jsonFormat2(Player)
  implicit val versionedPlayerFormat = jsonFormat2(VersionStamped[Player])

}
