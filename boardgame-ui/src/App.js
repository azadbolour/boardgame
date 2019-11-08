/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module App - top level app */
import React from 'react';
import PropTypes from 'prop-types';
import { Router } from "@reach/router"
import WelcomeComponent from "./component/WelcomeComponent"
import RequiredLoginContainer from "./component/RequiredLoginContainer"
import GameComponent from "./component/GameComponent"

class App extends React.Component {

  static propTypes = {
    isLoggedIn: PropTypes.bool.isRequired
  };

  render() {
    return (
      <Router>
        <WelcomeComponent path="/" />
        <RequiredLoginContainer isLoggedIn={this.props.isLoggedIn}>
          <GameComponent />
        </RequiredLoginContainer>
      </Router>
    )
  }
}

export default App