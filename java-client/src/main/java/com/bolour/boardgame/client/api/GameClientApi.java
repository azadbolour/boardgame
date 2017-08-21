/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.api;

import com.bolour.boardgame.client.domain.*;
import com.bolour.util.rest.BasicCredentials;
import com.bolour.util.rest.RuntimeRestClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.List;

import static com.bolour.util.rest.ClientRestHelper.*;
import static java.lang.String.format;

public class GameClientApi implements IGameClientApi {

    private static final Logger logger = LoggerFactory.getLogger(GameClientApi.class);

    private final String baseUrl;
    private final BasicCredentials credentials;
    private final RestTemplate restTemplate;

    public GameClientApi(String baseUrl, BasicCredentials credentials) {
        this.baseUrl = baseUrl;
        this.credentials = credentials;
        this.restTemplate = createCredentialedRestTemplate(credentials);
    }

    @Override
    public void addPlayer(Player player) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<Player> requestEntity = new HttpEntity(player, headers);
        ResponseEntity<Void> responseEntity;

        String addPlayerUrl = baseUrl + "game/player";

        try {
            responseEntity = restTemplate.postForEntity(addPlayerUrl, requestEntity, Void.class);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        // TODO. Add player should return the player id. Consistent with start game.
    }

    @Override
    public Game startGame(GameParams gameParams, List<GridPiece> initGridPieces, List<Piece> initUserTray, List<Piece> initMachineTray) {
        HttpHeaders headers = createJsonPostHeaders();
        // Note. The API needs a tuple, which in Java is an array of objects.
        Object[] tuplePayload = new Object[] {gameParams, initGridPieces, initUserTray, initMachineTray};
        HttpEntity<Player> requestEntity = new HttpEntity(tuplePayload, headers);
        ResponseEntity<Game> responseEntity;

        String startGameUrl = baseUrl + "game/game";

        try {
            responseEntity = restTemplate.postForEntity(startGameUrl, requestEntity, Game.class);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        Game gameDto = getResponseBody(responseEntity, restDescription());
        return gameDto;
    }

    @Override
    public List<Piece> commitPlay(String gameId, List<PlayPiece> playPieces) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<List<PlayPiece>> requestEntity = new HttpEntity(playPieces, headers);
        ResponseEntity<List<Piece>> responseEntity;

        String commitPlayUrl = baseUrl + "game/commit-play/{gameId}";

        try {
            responseEntity = restTemplate.exchange(commitPlayUrl, HttpMethod.POST, requestEntity,
              new ParameterizedTypeReference<List<Piece>>() {}, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        List<Piece> replacementPieces = getResponseBody(responseEntity, restDescription());
        return replacementPieces;
    }

    @Override
    public List<PlayPiece> machinePlay(String gameId) {
        // HttpHeaders headers = createJsonGetHeaders();
        ResponseEntity<List<PlayPiece>> responseEntity;

        String endGameUrl = baseUrl + "game/machine-play/{gameId}";
        try {
            responseEntity = restTemplate.exchange(endGameUrl, HttpMethod.POST, HttpEntity.EMPTY,
              new ParameterizedTypeReference<List<PlayPiece>>() {}, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        List<PlayPiece> playPieces = getResponseBody(responseEntity, restDescription());
        return playPieces;
    }

    @Override
    public Piece swapPiece(String gameId, Piece piece) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<Piece> requestEntity = new HttpEntity(piece, headers);
        ResponseEntity<Piece> responseEntity;

        String swapPieceUrl = baseUrl + "game/swap-piece/{gameId}";

        try {
            responseEntity = restTemplate.postForEntity(swapPieceUrl, requestEntity, Piece.class, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        Piece newPiece = getResponseBody(responseEntity, restDescription());
        return newPiece;
    }

    @Override
    public void endGame(String gameId) {
        // HttpHeaders headers = createJsonPostHeaders();
        HttpEntity requestEntity = HttpEntity.EMPTY;
        ResponseEntity<Void> responseEntity;

        String endGameUrl = baseUrl + "game/end-game/{gameId}";
        try {
            responseEntity = restTemplate.postForEntity(endGameUrl, requestEntity, Void.class, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }
    }

    private String restDescription() {
        return format("rest call to %s", baseUrl);
    }
}
