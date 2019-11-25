
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import Cookies from 'js-cookie';
import React from 'react';
import {CODE_COOKIE} from "../event/AuthService";
import GameComponent from './GameComponent';
import WelcomeComponent from './WelcomeComponent';
import GameParams from "../domain/GameParams";
import {stringify} from "../util/Logger";
import GameService from "../service/GameService";
import {mkGameHandler} from "../event/GameHandler";
import PropTypes from "prop-types";
import App from "../App";

/**
 * Top-level container. Keep it real simple to begin with and
 * go directly to a game if logged in and to the Welcome page if not.
 */

// Wrap the component in withAuth. Use auth.isAuthenticated to check instead of cookie.
const HomeContainer = props => {

  // TODO. Check authenticated and get authenticated user.
  const userName = "You";

  if (userName !== undefined) {
    const ps = {...props, userName: {userName}};
    return <GameComponent {...ps} />;
  }
  else
    return <WelcomeComponent {...props} />;
};

HomeContainer.propTypes = {
  gameState: PropTypes.object.isRequired,
  gameEventHandler: PropTypes.object.isRequired,
  serverType: PropTypes.string.isRequired
};

export default HomeContainer;
