/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class Piece {
    public final char value;
    public final String pieceId;

    @JsonCreator
    public Piece(
      @JsonProperty("value") char value,
      @JsonProperty("pieceId") String pieceId
    ) {
        this.value = value;
        this.pieceId = pieceId;
    }
}
