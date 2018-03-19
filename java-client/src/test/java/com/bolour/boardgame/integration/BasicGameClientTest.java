/*
 * Copyright 2017-2018-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.integration;


import com.bolour.boardgame.client.api.GameClientApi;
import com.bolour.boardgame.client.api.IGameClientApi;
import com.bolour.boardgame.client.domain.*;
import com.bolour.boardgame.client.message.MachinePlayResponse;
import com.bolour.boardgame.client.message.StartGameRequest;
import com.bolour.boardgame.client.message.StartGameResponse;
import com.bolour.boardgame.client.message.SwapPieceResponse;
import com.bolour.util.rest.BasicCredentials;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static java.lang.String.format;
import static java.util.Collections.EMPTY_LIST;
import static junit.framework.TestCase.assertTrue;

public class BasicGameClientTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(BasicGameClientTest.class);

    private List<List<Integer>> mkPointValues(int dimension) {
        List<Integer> row = new ArrayList<>(dimension);
        for (int i = 0; i < dimension; i++)
            row.add(2);

        List<List<Integer>> pointValues = new ArrayList<>(dimension);
        for (int i = 0; i < dimension; i++)
            pointValues.add(row);

        return pointValues;
    }

    @Test
    public void testStartGame() throws Exception {
        String baseUrl = "http://localhost:6587";
        BasicCredentials credentials = new BasicCredentials("admin", "admin");
        IGameClientApi client = new GameClientApi(baseUrl, credentials);

        String name = UUID.randomUUID().toString().replace("-", "dash");
        Player player = new Player(name);
        client.addPlayer(player);

        int dimension = 15;
        int numTrayPieces = 7;

        // TODO. Provide the initial trays and board so that a real word may be committed by user.
        // Add a commit play interaction.

        // TODO. PieceProviderType enum.
        GameParams gameParams = new GameParams(dimension, numTrayPieces, "en", name, "Random");
        List<List<Integer>> pointValues = mkPointValues(dimension);
        StartGameRequest startRequest = new StartGameRequest(gameParams, EMPTY_LIST, EMPTY_LIST, EMPTY_LIST, pointValues);
        StartGameResponse startResponse = client.startGame(startRequest);

        String gameId = startResponse.gameId;
        List<Piece> trayPieces = startResponse.trayPieces;
        // TODO. Create function mapList in util.
        List<Character> letters = trayPieces.stream().map(piece -> piece.value).collect(Collectors.toList());
        LOGGER.info(format("tray pieces: %s", letters));
        Piece firstPiece = trayPieces.get(0);
        SwapPieceResponse swapResponse = client.swapPiece(gameId, firstPiece);
        Piece piece = swapResponse.piece;
        LOGGER.info(format("swapped %s for %s", firstPiece, piece));
        MachinePlayResponse machineResponse = client.machinePlay(gameId);
        List<Piece> machinePieces = machineResponse.playedPieces;
        assertTrue(machinePieces.size() > 1);
        // end game expects the game to have been ended.
        // TODO. Better api name than closeGame - closeGame.
        GameSummary summary = client.closeGame(gameId);

    }

}
