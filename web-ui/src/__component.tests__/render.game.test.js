/*
 * Copyright 2017 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */


// Not supported. Ignore.

jest.dontMock('../component/PieceComponent');
jest.dontMock('../component/GameComponent');
jest.dontMock('../component/TraySquareComponent');

import React from 'react';
import ReactDOM from 'react-dom';
const DragDropContext = require('react-dnd').DragDropContext;
// TODO. change: react-addons-test-utils as react-dom/test-utils
import TestUtils from 'react-addons-test-utils'
import TestBackend from 'react-dnd-test-backend';

import OriginalGameComponent from '../component/GameComponent';
import OriginalPieceComponent from '../component/PieceComponent';
import TraySquareComponent from '../component/TraySquareComponent';
import Game from '..//domain/Game';
import Board from '../domain/Board';
import Piece from '../domain/Piece';
import GameParams from '../domain/GameParams';

const Component = React.Component;

// Experimental. Not part of the main test suite.
// TODO. Got error TypeError: originalGameComponent.getHandlerId trying to simulate
// TODO. To continue see https://react-dnd.github.io/react-dnd/docs-testing.html.
// Have had minimal success with this type of testing.

function wrapInTestContext(DecoratedComponent) {
  return DragDropContext(TestBackend)(
    create-react-class({
      render: function () {
        return <DecoratedComponent {...this.props} />;
      }
    })
  );
}

function mkGame() {
  let gameParams = GameParams.defaultParams();
  let gameId = 1;
  let dimension = gameParams.dimension;
  let trayCapacity = gameParams.trayCapacity;
  let b = new Board(dimension);
  let cells = b.pieces;

  let json = {
    gameId: gameId,
    board: {
      width: dimension,
      height: dimension,
      grid: {
        cells: cells
      }
    },
    tray: {
      pieces: (new Array(trayCapacity)).fill(new Piece('A', '1'))
    }
  };

  return Game.fromJson(json, gameParams);
}

it('should render game', function() {
  let DragDropGameComponent = wrapInTestContext(OriginalGameComponent);
  let game = mkGame();
  let root = TestUtils.renderIntoDocument(<DragDropGameComponent game={game} />);

  let backend = root.getManager().getBackend();

  let originalGameComponent = TestUtils.findRenderedComponentWithType(root, OriginalGameComponent);
  let props = originalGameComponent.props;
  // console.log(`game component props: ${JSON.stringify(props)}`); // Shows the full game.
  expect(props.game.squarePixels).toBe(game.squarePixels);

  let traySquareComponents = TestUtils.scryRenderedComponentsWithType(root, TraySquareComponent);
  expect(traySquareComponents.length).toBeGreaterThan(0);
  let square = traySquareComponents[0];
  // TODO. I think you need to get the associated DOM element and use it as the first argument of find.
  // TODO. But I don't know how to do that.
  // let pieceComponent = TestUtils.findRenderedComponentsWithType(square, OriginalPieceComponent);

  // Let's just get all the pieces.

  let originalPieceComponents = TestUtils.scryRenderedComponentsWithType(root, OriginalPieceComponent);
  expect(originalPieceComponents.length).toBeGreaterThan(0);
  // console.log(`num pieces found: ${originalPieceComponents.length}`);

  // TODO. The following shows that the tray pieces come out first. Should be able to drag them. But can't yet.
  // originalPieceComponents.forEach( p => {
  //   console.log(`${JSON.stringify(p.props)}`);
  // });
  let originalPieceComponent = originalPieceComponents[0];
  // TODO. Error simulating begin drag.
  // TODO. Invariant Violation: Expected sourceIds to be registered.
  // backend.simulateBeginDrag([originalPieceComponent.getHandlerId()]);
  // TODO. Don't know how to test begin drag and or drop target.
  // TODO. simulate works for a wrapped Piece (see test below).
  // TODO. So it is unclear how to test deep hierarchies of components.
  // The descendants of a wrapped piece are not wrapped. That must be the issue.
});

it('should simulate drag for piece', function() {
  let DragDropGameComponent = wrapInTestContext(OriginalPieceComponent);
  let piece = new Piece('A', '1');
  let root = TestUtils.renderIntoDocument(<DragDropGameComponent piece={piece} />);
  let backend = root.getManager().getBackend();

  let originalPieceComponent = TestUtils.findRenderedComponentWithType(root, OriginalPieceComponent);
  let props = originalPieceComponent.props;
  expect(props.piece.value).toBe('A');
  backend.simulateBeginDrag([originalPieceComponent.getHandlerId()]);
});