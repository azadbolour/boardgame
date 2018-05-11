/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameParams;
import com.bolour.boardgame.client.domain.PiecePoint;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class StartGameResponse {

    public final String gameId;
    public final GameParams gameParams;
    public final List<PiecePoint> boardPiecePoints;
    public final List<Piece> trayPieces;

    @JsonCreator
    public StartGameResponse(
      @JsonProperty("gameId") String gameId,
      @JsonProperty("gameParams") GameParams gameParams,
      @JsonProperty("boardPiecePoints") List<PiecePoint> boardPiecePoints,
      @JsonProperty("trayPieces") List<Piece> trayPieces
    ) {
        this.gameId = gameId;
        this.gameParams = gameParams;
        this.boardPiecePoints = boardPiecePoints;
        this.trayPieces = trayPieces;
    }
    
}
