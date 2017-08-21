/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class PlayPiece {
    public final Piece piece;
    public final Point point;
    public final boolean moved;

    @JsonCreator
    public PlayPiece(
      @JsonProperty("piece") Piece piece,
      @JsonProperty("point") Point point,
      @JsonProperty("moved") boolean moved
    ) {
        this.piece = piece;
        this.point = point;
        this.moved = moved;
    }
}
