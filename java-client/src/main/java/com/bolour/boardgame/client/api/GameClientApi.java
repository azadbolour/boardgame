/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

package com.bolour.boardgame.client.api;

import com.bolour.boardgame.client.domain.*;
import com.bolour.boardgame.client.message.*;
import com.bolour.util.rest.BasicCredentials;
import com.bolour.util.rest.RuntimeRestClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
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
    public void addPlayer(PlayerDto player) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<PlayerDto> requestEntity = new HttpEntity(player, headers);
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
    public StartGameResponse startGame(StartGameRequest request) {
        HttpHeaders headers = createJsonPostHeaders();
        // Note. The API needs a tuple, which in Java is an array of objects.
        // Object[] tuplePayload = new Object[] {gameParams, initGridPieces, initUserTray, initMachineTray};
        HttpEntity<PlayerDto> requestEntity = new HttpEntity(request, headers);
        ResponseEntity<StartGameResponse> responseEntity;

        String startGameUrl = baseUrl + "game/game";

        try {
            responseEntity = restTemplate.postForEntity(startGameUrl, requestEntity, StartGameResponse.class);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        StartGameResponse response = getResponseBody(responseEntity, restDescription());
        return response;
    }

    // Boilerplate for later use.
    // responseEntity = restTemplate.exchange(commitPlayUrl, HttpMethod.POST, requestEntity,
    // new ParameterizedTypeReference<List<Piece>>() {}

    @Override
    public CommitPlayResponse commitPlay(String gameId, List<PlayPiece> playPieces) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<List<PlayPiece>> requestEntity = new HttpEntity(playPieces, headers);
        ResponseEntity<CommitPlayResponse> responseEntity;

        String url = baseUrl + "game/commit-play/{gameId}";

        try {
            responseEntity = restTemplate.postForEntity(url, requestEntity, CommitPlayResponse.class, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        CommitPlayResponse response = getResponseBody(responseEntity, restDescription());
        return response;
    }

    @Override
    public MachinePlayResponse machinePlay(String gameId) {
        // HttpHeaders headers = createJsonGetHeaders();
        ResponseEntity<MachinePlayResponse> responseEntity;

        String url = baseUrl + "game/machine-play/{gameId}";
        try {
            responseEntity = restTemplate.postForEntity(url, HttpEntity.EMPTY, MachinePlayResponse.class, gameId);

        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        MachinePlayResponse response = getResponseBody(responseEntity, restDescription());
        return response;
    }

    @Override
    public SwapPieceResponse swapPiece(String gameId, Piece piece) {
        HttpHeaders headers = createJsonPostHeaders();
        HttpEntity<Piece> requestEntity = new HttpEntity(piece, headers);
        ResponseEntity<SwapPieceResponse> responseEntity;

        String url = baseUrl + "game/swap-piece/{gameId}";

        try {
            responseEntity = restTemplate.postForEntity(url, requestEntity, SwapPieceResponse.class, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        SwapPieceResponse response = getResponseBody(responseEntity, restDescription());
        return response;
    }

    // Note. For void response: use ResponseEntity<Void>, and Void.class.

    @Override
    public GameSummary closeGame(String gameId) {
        // HttpHeaders headers = createJsonPostHeaders();
        HttpEntity requestEntity = HttpEntity.EMPTY;
        ResponseEntity<GameSummary> responseEntity;

        String endGameUrl = baseUrl + "game/close-game/{gameId}";
        try {
            responseEntity = restTemplate.postForEntity(endGameUrl, requestEntity, GameSummary.class, gameId);
        }
        catch (Throwable th) {
            throw new RuntimeRestClientException(th);
        }

        GameSummary response = getResponseBody(responseEntity, restDescription());
        return response;
    }

    private String restDescription() {
        return format("rest call to %s", baseUrl);
    }
}
