package com.bolour.boardgame.scala.server.service.json

import com.bolour.boardgame.scala.common.domain.{Piece, PiecePoint, PlayPiece}
import com.bolour.boardgame.scala.server.domain._
import com.bolour.boardgame.scala.server.service.GameData
import com.bolour.plane.scala.domain.Point
import com.bolour.util.scala.common.VersionStamped
import spray.json._

object CaseClassFormats extends DefaultJsonProtocol {

  import com.bolour.boardgame.scala.server.domain.json.PlayJsonProtocol.PlayJsonFormat
  import com.bolour.boardgame.scala.server.domain.json.CaseClassFormats.gameBaseFormat

  implicit def gameDataFormat = jsonFormat2(GameData.apply)
  implicit def versionedGameDataFormat = jsonFormat2(VersionStamped[GameData])
}
