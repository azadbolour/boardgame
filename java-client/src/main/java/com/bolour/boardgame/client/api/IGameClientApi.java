/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.api;

import com.bolour.boardgame.client.domain.*;

import java.util.List;

public interface IGameClientApi {

    void addPlayer(Player player);

    Game startGame(GameParams gameParams, List<GridPiece> initGridPieces,
                   List<Piece> initUserTray, List<Piece> initMachineTray);

    List<Piece> commitPlay(String gameId, List<PlayPiece> playPieces);

    List<PlayPiece> machinePlay(String gameId);

    Piece swapPiece(String gameId, Piece piece);

    void endGame(String gameId);
}
