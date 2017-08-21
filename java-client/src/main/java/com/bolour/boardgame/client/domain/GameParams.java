/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.domain;

public class GameParams {
    public final int height, width;
    public final int trayCapacity;
    public final String languageCode;
    public final String playerName;

    public GameParams(int height, int width, int trayCapacity, String languageCode, String playerName) {
        this.height = height;
        this.width = width;
        this.trayCapacity = trayCapacity;
        this.languageCode = languageCode;
        this.playerName = playerName;
    }
}
