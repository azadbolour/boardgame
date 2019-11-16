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
 * The response from a logout call to the authentication service
 * is redirected here.
 *
 * TODO. Just assume that it worked and remove the token cookie.
 *
 */
export const LogoutRedirectContainer = props => {

};

export default LogoutRedirectContainer;