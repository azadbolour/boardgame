/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module LoginTokenReceiverComponent - receives and processes redirect from login */

import React from 'react';
import PropTypes from 'prop-types';
import HomeContainer from "./component/HomeContainer"
import {queryParams} from './util/UrlUtil';
import {stringify} from "./util/Logger";
import {mkGameState} from "./GameState";

/**
 * The response from a login call to the authentication service
 * is redirected here. The redirect has the following parameters:
 *
 *   code=AUTH_CODE&state=whatWasTransmittedInTheLoginRequest
 *   error=access_denied in the query string - is it the same for Cognito?
 *   Bottom line is that there will be an error parameter in the query string.
 */
export const LoginRedirectContainer = props => {
  // TODO. Create initial gameState here.
  const gameState = null;
  const gameEventHandler = props.gameEventHandler;
  console.log(`LoginRedirectContainer - location: ${stringify(window.location)}`);
  const urlQueryParams = queryParams(window.location);
  const token = urlQueryParams["code"];  // TODO. Constants.
  const state = urlQueryParams["state"];
  const error = urlQueryParams["error"];

  // TODO. Also check state === transmitted state
  // TODO. How to keep track of transmitted state safely?
  if (error === undefined) {
    // TODO. Set cookie for token.
  }
  else {
    // store token in cookie or local or session storage
  }
  return (
    <HomeContainer error={error} />
  )
};





export default LoginRedirectContainer;