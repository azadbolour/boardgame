/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class GameParams {
    public final int dimension;
    public final int trayCapacity;
    public final String languageCode;
    public final String playerName;
    public final String pieceProviderType;

    @JsonCreator
    public GameParams(
      @JsonProperty("dimension") int dimension,
      @JsonProperty("trayCapacity") int trayCapacity,
      @JsonProperty("languageCode") String languageCode,
      @JsonProperty("playerName") String playerName,
      @JsonProperty("pieceProviderType") String pieceProviderType
    ) {
        this.dimension = dimension;
        this.trayCapacity = trayCapacity;
        this.languageCode = languageCode;
        this.playerName = playerName;
        this.pieceProviderType = pieceProviderType;
    }
}
