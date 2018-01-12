/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.message;

import com.bolour.boardgame.client.domain.GameParams;
import com.bolour.boardgame.client.domain.GridPiece;
import com.bolour.boardgame.client.domain.Piece;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class StartGameResponse {

    public final String gameId;
    public final GameParams gameParams;
    public final List<GridPiece> gridPieces;
    public final List<Piece> trayPieces;

    @JsonCreator
    public StartGameResponse(
      @JsonProperty("gameId") String gameId,
      @JsonProperty("gameParams") GameParams gameParams,
      @JsonProperty("gridPieces") List<GridPiece> gridPieces,
      @JsonProperty("trayPieces") List<Piece> trayPieces
    ) {
        this.gameId = gameId;
        this.gameParams = gameParams;
        this.gridPieces = gridPieces;
        this.trayPieces = trayPieces;
    }
    
}
