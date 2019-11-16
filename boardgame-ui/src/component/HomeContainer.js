
/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import GameComponent from './GameComponent';
import WelcomeComponent from './WelcomeComponent';

// TODO. Make sure props.loginState has been initialized properly.
/**
 * Top-level container. Keep it real simple to begin with and
 * go directly to a game if logged in and to the Welcome page if not.
 */
export const HomeContainer = props => {
  if (props.loginState.isUserLoggedIn)
    return (GameComponent(props)); // TODO. OK to just call the component function?
  else
    return (WelcomeComponent(props));
};
