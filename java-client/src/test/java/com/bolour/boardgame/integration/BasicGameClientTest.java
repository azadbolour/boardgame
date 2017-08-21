/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.integration;


import com.bolour.boardgame.client.api.GameClientApi;
import com.bolour.boardgame.client.api.IGameClientApi;
import com.bolour.boardgame.client.domain.*;
import com.bolour.util.rest.BasicCredentials;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import static java.lang.String.format;
import static java.util.Collections.EMPTY_LIST;
import static junit.framework.TestCase.assertTrue;

public class BasicGameClientTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(BasicGameClientTest.class);

    @Test
    public void testStartGame() throws Exception {
        String baseUrl = "http://localhost:6587";
        BasicCredentials credentials = new BasicCredentials("admin", "admin");
        IGameClientApi client = new GameClientApi(baseUrl, credentials);

        String name = UUID.randomUUID().toString().replace("-", "dash");
        Player player = new Player(name);
        client.addPlayer(player);

        int height = 15;
        int width = 15;
        int numTrayPieces = 7;

        // TODO. Provide the initial trays and board so that a real word may be committed by user.
        // Add a commit play interaction.

        GameParams gameParams = new GameParams(height, width, numTrayPieces, "en", name);
        Game gameDto = client.startGame(gameParams, EMPTY_LIST, EMPTY_LIST, EMPTY_LIST);
        String gameId = gameDto.gameId;
        List<Piece> trayPieces = gameDto.trayPieces;
        // TODO. Create function mapList in util.
        List<Character> letters = trayPieces.stream().map(piece -> piece.value).collect(Collectors.toList());
        LOGGER.info(format("tray pieces: %s", letters));
        Piece firstPiece = gameDto.trayPieces.get(0);
        Piece newPiece = client.swapPiece(gameId, firstPiece);
        LOGGER.info(format("swapped %s for %s", firstPiece, newPiece));
        List<PlayPiece> playPieces = client.machinePlay(gameId);
        assertTrue(playPieces.size() > 1);
        client.endGame(gameId);
    }

}
