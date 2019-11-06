/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


import GameParams from '../domain/GameParams';
import MockApi from './MockApi';
import ClientApi from './ClientApi';

/**
 * Select the api implementation to use for a game - mock or game server client.
 */
export const apiSelector = function(gameParams) {
  let userName = gameParams.appParams.userName;
  let password = gameParams.appParams.password;
  let url = gameParams.appParams.serverUrl;
  let mockApi = new MockApi(url, userName, password);
  let clientApi = new ClientApi(url, userName, password)

  switch (gameParams.apiType) {
    case GameParams.MOCK_API_TYPE:
      return mockApi;
    case GameParams.CLIENT_API_TYPE:
      return clientApi;
    default:
      return mockApi;
  }
};
