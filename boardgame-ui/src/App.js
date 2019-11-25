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
import Amplify from '@aws-amplify/core';
import Auth from '@aws-amplify/auth';
import {configuration} from './aws-exports';
import {stringify} from "./util/Logger";

Amplify.configure(configuration);
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
        </Switch>
      </Router>
    )
};

App.propTypes = {
  gameState: PropTypes.object.isRequired,
  gameEventHandler: PropTypes.object.isRequired,
  serverType: PropTypes.string.isRequired
};

const authenticationParams = {includeGreetings: true};

export default withAuthenticator(App, authenticationParams);