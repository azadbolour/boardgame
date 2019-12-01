/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module App - top level app */
import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter as Router, Redirect, Route, Switch} from 'react-router-dom';
import {stringify} from "./util/Logger";
import LandingComponent from "./component/LandingComponent";

const NotFound = () => <p>Page not found!</p>;

/**
 * The App component just does the routing. For now, everything goes to the
 * landing component, which knows about authentication. IndexRedirect is the default.
 */
const App = props => {
    return (
      <Router>
        <Switch>
          <Route
            path='/' exact={true}
            render={(routeProps) => <LandingComponent {...routeProps}
              gameState={props.gameState}
              gameEventHandler={props.gameEventHandler}
              serverType={props.serverType}
            />}
          />
          <Redirect path="*" to="/" />
        </Switch>
      </Router>
    )
};

App.propTypes = {
  gameState: PropTypes.object.isRequired,
  gameEventHandler: PropTypes.object.isRequired,
  serverType: PropTypes.string.isRequired
};

export default App