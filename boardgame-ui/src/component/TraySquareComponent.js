/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module TraySquare */

import React from 'react';
import PropTypes from 'prop-types';
import Square from './SquareComponent';
import {mkPiece} from '../domain/Piece';
import actions from '../event/GameActions';
const ItemTypes = require('./DragDropTypes').ItemTypes;
const DropTarget = require('react-dnd').DropTarget;

// TODO. Duplicated in BoardSquareComponent. DRY.
function colorCodedLegalMoveStyle(pixels, colorCoding) {
  const pix = pixels + 'px';
  return {
    position: 'absolute',
    top: 0,
    left: 0,
    height: pix,
    width: pix,
    zIndex: 1,
    opacity: 0.5,
    backgroundColor: colorCoding
  };
}
/**
 * Style for the square - it is relative to its siblings within its parent.
 */
function squareStyle(squarePixels) {
  const pix = squarePixels + 'px';
  return {
    position: 'relative',
    width: pix,
    height: pix
  };
}

/**
 * Get the shade of the checker at the given position - light or dark square.
 */
function checkerShade(position) {
  return (position) % 2 === 0 ? 'light' : 'dark'; // TODO. Constants.
}

const pieceDropper = {
  canDrop: function (props, monitor) {
    let pieceItem = monitor.getItem();
    let piece = mkPiece(pieceItem.value, pieceItem.id);
    let can = !props.isTrayPiece(piece);
    return can;
  },

  drop: function (props, monitor) {
    console.log("dropping");
    let draggedPiece = monitor.getItem();
    let piece = mkPiece(draggedPiece.value, draggedPiece.id);
    let game = props.gameState.game;
    let auxGameData = props.gameState.auxGameData;
    props.gameEventHandler.revertMove(game, auxGameData, piece);
  }
};

function injectedDropTargetProperties(connect, monitor) {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver(),
    canDrop: monitor.canDrop()
  };
}

/**
 * A given square on the board.
 *
 * The parent component (Board), being wrapped in a drag-drop context,
 * passes drag-drop properties to its children. They include isOver,
 * and canDrop.
 *
 * Note that the position of the square is a plain javascript
 * object with row and col fields. React dnd needs plain objects to
 * act as dragged items. That is why we did not abstract
 * board position to its own class. There were issues with
 * class instances and react dnd.
 */
class TraySquareComponent extends React.Component {

  static propTypes = {
    position: PropTypes.number.isRequired,
    isTrayPiece: PropTypes.func.isRequired,
    squarePixels: PropTypes.number.isRequired,
    enabled: PropTypes.bool.isRequired,

    /**
     * Is the cursor over the current square?
     */
    isOver: PropTypes.bool.isRequired,

    canDrop: PropTypes.bool.isRequired,

    gameState: PropTypes.object.isRequired,

    /**
     * Handler of user actions.
     */
    gameEventHandler: PropTypes.object.isRequired
  };

  render() {
    let connectDropTarget = this.props.connectDropTarget;
    let shade = checkerShade(this.props.position);
    // let squarePixels = this.props.squarePixels;
    let isLight = (shade === 'light'); // TODO. Constant.
    // let backgroundColor = 'CornSilk';
    let backgroundColor = isLight ? 'CornSilk' : '#FFD040';
    let color = 'FireBrick';
    let enabled = this.props.enabled;
    let isOver = this.props.isOver;
    let canDrop = this.props.canDrop;
    let pixels = this.props.squarePixels;

    return connectDropTarget(
      <div style={squareStyle(pixels)}>
        <Square
          pixels={pixels}
          color={color}
          backgroundColor={backgroundColor}
          enabled={enabled} >
          {this.props.children}
        </Square>

        {isOver && !canDrop && <div style={colorCodedLegalMoveStyle(pixels, 'red')} />}
        {!isOver && canDrop && <div style={colorCodedLegalMoveStyle(pixels, 'yellow')} />}
        {isOver && canDrop && <div style={colorCodedLegalMoveStyle(pixels, 'green')} />}

      </div>
    );
  }
}

// export default TraySquareComponent;

export default DropTarget(ItemTypes.PIECE, pieceDropper, injectedDropTargetProperties)(TraySquareComponent);