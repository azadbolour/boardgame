/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module App - top level app */
import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import { withAuthenticator } from 'aws-amplify-react';
import HomeContainer from "./component/HomeContainer";
import GameComponent from "./component/GameComponent";
import Amplify from 'aws-amplify';
import {Auth} from 'aws-amplify';
import {configuration} from './aws-exports';
import {stringify} from "./util/Logger";

Amplify.configure(configuration);
const auth = configuration.auth;
Auth.configure({ auth });

const NotFound = () => <p>Page not found!</p>;

const App = props => {
    return (
      <Router>
        <Switch>
          <Route
            path='/' exact={true}
            render={(routeProps) => <HomeContainer {...routeProps}
              gameState={props.gameState}
              gameEventHandler={props.gameEventHandler}
              serverType={props.serverType}
            />}
          />
          <Route path='/games' exact={true}
            render={(routeProps) => <GameComponent {...routeProps}
              gameState={props.gameState}
              gameEventHandler={props.gameEventHandler}
              serverType={props.serverType}
            />}
          />

        </Switch>
      </Router>
    )
};

App.propTypes = {
  gameState: PropTypes.object.isRequired,
  gameEventHandler: PropTypes.object.isRequired,
  serverType: PropTypes.string.isRequired
};

// const authenticationParams = {includeGreetings: true};

// export default withAuthenticator(App, authenticationParams);
export default App