/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module LoginTokenReceiverComponent - receives and processes redirect from login */

import React from 'react';
import PropTypes from 'prop-types';
import GameComponent from "./component/GameComponent"

/**
 * The response from a login call to the authentication service
 * is redirected here. The redirect has the following parameters:
 *
 *   code=AUTH_CODE&state=whatWasTransmittedInTheLoginRequest
 */
export const LoginRedirectContainer = props => {

  // the response has: code=AUTH_CODE&state=sameRandomness
  // TODO. How do we detect an error?

  // error=access_denied in the query string - is it the same for Cognito?
  // Bottom line is that there will be an error parameter in the query string.

  // TODO. Get the code and the state.
  // TODO. Check state param against saved state.
  // If OK - save token and render the game.

  // TODO. Set the state and notify the observer to render the game.
  // Or how about just redirecting to / and let home figure it out?
};

export default LoginRedirectContainer;