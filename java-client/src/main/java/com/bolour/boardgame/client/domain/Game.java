/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.Collections;
import java.util.List;

// TODO. Remove.
public class Game {
    public final String gameId;
    public final String languageCode;
    public final int height, width;
    public final int trayCapacity;
    public final List<GridPiece> gridPieces;
    public final List<Piece> trayPieces;
    public final String player;

    @JsonCreator
    public Game(
      @JsonProperty("gameId") String gameId,
      @JsonProperty("languageCode") String languageCode,
      @JsonProperty("height") int height,
      @JsonProperty("width") int width,
      @JsonProperty("trayCapacity") int trayCapacity,
      @JsonProperty("gridPieces") List<GridPiece> gridPieces,
      @JsonProperty("trayPieces") List<Piece> trayPieces,
      @JsonProperty("player") String player
    ) {
        this.gameId = gameId;
        this.languageCode = languageCode;
        this.height = height;
        this.width = width;
        this.trayCapacity = trayCapacity;
        this.gridPieces = Collections.unmodifiableList(gridPieces);
        this.trayPieces = Collections.unmodifiableList(trayPieces);
        this.player = player;
    }
}
