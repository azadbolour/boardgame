/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module App - top level app */
import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter as Router, Route } from 'react-router-dom';
import HomeContainer from "./component/HomeContainer";
import Amplify from '@aws-amplify/core';
import Auth from '@aws-amplify/auth';
import {configuration} from './aws-exports';

Amplify.configure(configuration);
const NotFound = () => <p>Page not found!</p>;

// TODO. Where do you inject props for the application?
// Don't see how to do that with Reach Router.
// TODO. Convert to ReactRouter - can provide renderer that allows props
// Do we need any props? At the top level should not have any props.

// TODO. To pass props - you'll need to use render.
// e.g., render={(props) => <Dashboard {...props} isAuthed={true} />}

const App = props => {
    return (
      <Router>
        <Route path='/' exact={true} component={HomeContainer}/>
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