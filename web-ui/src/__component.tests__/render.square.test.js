/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

// Not supported. Ignore.

jest.dontMock('../component/SquareComponent');

import React from 'react';
import ReactDOM from 'react-dom';

import SquareComponent from '../component/SquareComponent';
import TestUtils from 'react-addons-test-utils'

// Experimental. Not part of the main test suite.
// TODO. To continue see https://react-dnd.github.io/react-dnd/docs-testing.html.
// TODO. Not a sufficient amount of examples for latest version of TestUtils.
// Minimally documented and in a state of flux.
// Have had minimal success with this type of testing.

const COLOR = 'Red';
const BACKGROUND_COLOR = 'Blue';
const PIXELS = 100;
it('should render square', function() {
  let component = TestUtils.renderIntoDocument(
    <SquareComponent pixels={PIXELS} color={COLOR} backgroundColor={BACKGROUND_COLOR} >
      // It has a single div.
    </SquareComponent>);
  let found = TestUtils.scryRenderedDOMComponentsWithTag(component, 'div');
  expect(found.length).toBe(1);

  let props = component.props;
  expect(props.pixels).toBe(PIXELS);
  expect(props.color).toBe(COLOR);
  expect(props.backgroundColor).toBe(BACKGROUND_COLOR);
  
});