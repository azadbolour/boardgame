/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.api;

import com.bolour.boardgame.client.domain.*;
import com.bolour.boardgame.client.message.*;

import java.util.List;

public interface IGameClientApi {

    void addPlayer(Player player);

    StartGameResponse startGame(StartGameRequest request);

    CommitPlayResponse commitPlay(String gameId, List<PlayPiece> playPieces);

    MachinePlayResponse machinePlay(String gameId);

    SwapPieceResponse swapPiece(String gameId, Piece piece);

    GameSummary closeGame(String gameId);
}
