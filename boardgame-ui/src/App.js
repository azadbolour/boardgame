/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module App - top level app */
import React from 'react';
import PropTypes from 'prop-types';
import { Router } from "@reach/router";
import HomeContainer from "./component/HomeContainer";
import LoginRedirectContainer from "./component/LoginRedirectContainer";
import LogoutRedirectContainer from "./component/LogoutRedirectContainer";
import {LOGIN_REDIRECT_PATH, LOGOUT_REDIRECT_PATH} from './event/AuthService';

const NotFound = () => <p>Page not found!</p>;

// TODO. Where do you inject props for the application?
// Don't see how to do that with Reach Router.
// TODO. Convert to ReactRouter - can provide renderer that allows props
// Do we need any props? At the top level should not have any props.

const App = props => {
  // TODO. Do the props propagate this way?
    return (
      <Router>
        <HomeContainer path="/" props={props}/>
        <LoginRedirectContainer path={LOGIN_REDIRECT_PATH} />
        <LogoutRedirectContainer path={LOGOUT_REDIRECT_PATH} />
        <NotFound default />
      </Router>
    )
};

// TODO. Verify that at top level we don't need any props.
// App.propTypes = {
//   loginState: PropTypes.object.isRequired,
//   gameState: PropTypes.object.isRequired,
//   gameEventHandler: PropTypes.object.isRequired,
//   serverType: PropTypes.string.isRequired
// };

export default App