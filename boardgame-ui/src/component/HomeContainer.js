
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import GameComponent from './GameComponent';
import WelcomeComponent from './WelcomeComponent';

// TODO. Implement token expiration.

/**
 * Top-level container. Keep it real simple to begin with and
 * go directly to a game if logged in and to the Welcome page if not.
 */

// TODO. Home component should have an error prop - send to WelcomeComponent.
// TODO. What about the gameState, etc.
// TODO. Should index.js functionality be moved to here?

export const HomeContainer = props => {

  // TODO. This is where props will be injected.
  // Add in the props.

  const token = null; // Get token from cookie or storage.

  if (token !== undefined)
    return (GameComponent(props));
  else
    return (WelcomeComponent(props));
};
