/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class Point {
    public final int row, col;

    @JsonCreator
    public Point(
      @JsonProperty("row") int row,
      @JsonProperty("col") int col
    ) {
        this.row = row;
        this.col = col;
    }
}
