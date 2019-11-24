
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import Cookies from 'js-cookie';
import {CODE_COOKIE} from "../event/AuthService";
import GameComponent from './GameComponent';
import WelcomeComponent from './WelcomeComponent';

/**
 * Top-level container. Keep it real simple to begin with and
 * go directly to a game if logged in and to the Welcome page if not.
 */

// TODO. Home component should have an error prop - send to WelcomeComponent.
// TODO. What about the gameState, etc.
// TODO. Should index.js functionality be moved to here?


  // TODO. Remove cookie.
  // Wrap the component in withAuth. Use auth.isAuthenticated to check instead of cookie.
export const HomeContainer = props => {

  // TODO. This is where props will be injected.
  // Add in the props.

  const authCode = Cookies.get(CODE_COOKIE);

  if (authCode !== undefined)
    return (GameComponent(props));
  else
    return (WelcomeComponent(props));
};
