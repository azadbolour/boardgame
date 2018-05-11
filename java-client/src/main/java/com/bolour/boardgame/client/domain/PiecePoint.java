/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class PiecePoint {
    public final Piece piece;
    public final Point point;

    @JsonCreator
    public PiecePoint(
      @JsonProperty("piece") Piece piece,
      @JsonProperty("point") Point point
    ) {
        this.piece = piece;
        this.point = point;
    }
}
