/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class PiecePoint {
    // This name 'val' is used in the API for a generic value.
    // But here we just need a piece. So keep the name val but duplicate it to piece.
    // TODO. The API should be cleaned up to just use specific names. Then remove generic name 'val'.
    public final Piece value;
    public final Piece piece;
    public final Point point;

    @JsonCreator
    public PiecePoint(
      @JsonProperty("value") Piece value,
      @JsonProperty("point") Point point
    ) {
        this.value = value;
        this.point = point;
        this.piece = value;
    }
}
