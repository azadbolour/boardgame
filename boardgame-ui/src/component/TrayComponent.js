/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Tray */
import React from 'react';
import PropTypes from 'prop-types';
import PieceComponent from './PieceComponent';
import TraySquareComponent from './TraySquareComponent';
import * as Piece from '../domain/Piece';

/**
 * A style that includes the board's overall
 * dimensions in pixels, and the layout of its
 * children (the board's squares).
 */
function trayStyle(trayCapacity, squarePixels) {
  const width = trayCapacity * squarePixels
  return {
    width: width + 'px',
    height: squarePixels + 'px',
    display: 'flex',
    flexWrap: 'wrap'
  };
}

/**
 * A style that includes the dimensions of a board square
 * in pixels.
 */
function squareStyle(squarePixels) {
  let pix = squarePixels + 'px';
  return { width: pix, height: pix };
}

/**
 * User interface component representing tray of available pieces.
 */
class TrayComponent extends React.Component {
  static propTypes = {
    pieces: PropTypes.array.isRequired,
    canMovePiece: PropTypes.func.isRequired,
    squarePixels: PropTypes.number.isRequired,
    enabled: PropTypes.bool.isRequired
  };
  
  /**
   * Return the UI specification of the piece that goes into
   * a specific board square - given the square's position.
   */
  renderPiece(position) {
    return <PieceComponent piece={this.props.pieces[position]} canMovePiece={this.props.canMovePiece} />;
  }

  /**
   * Return the UI specification of a single square based
   * on its position in the tray.
   *
   * A function may return the react specification of a
   * UI component, and these specifications may be composed.
   */
  renderSquare(position) {
    let squareKey = position;
    let squarePixels = this.props.squarePixels;
    let pieces = this.props.pieces;
    let isTrayPiece = function(piece) {
      let index = pieces.findIndex(pce => Piece.eq(pce, piece));
      let exists = index >= 0;
      return exists;
    };
    let enabled = this.props.enabled;

    return (
      <div key={squareKey} style={squareStyle({squarePixels})}>
        <TraySquareComponent
          position={position}
          isTrayPiece={isTrayPiece}
          squarePixels={squarePixels}
          enabled={enabled} >
          {this.renderPiece(position)}
        </TraySquareComponent>
      </div>
    );
  }

  /**
   * Render all the squares on the tray by accumulating their
   * specifications in an array and interpolating the array as
   * the child of a div component. The div component has a style
   * with the correct overall size of the board. See boardStyle.
   */
  render() {
    let trayCapacity = this.props.pieces.length;
    let squarePixels = this.props.squarePixels;
    let squares = [];

    for (let position = 0; position < trayCapacity; position++)
      squares.push(this.renderSquare(position));

    return (
      <div style={trayStyle(trayCapacity, squarePixels)}>
        {squares}
      </div>
    );
  }

}

/**
 * The opponent's tray of pieces.
 *
 * <p>
 * The tray component is decorated with a drag-drop context.
 * The drag-drop contexts mixes in the drag-drop state, allowing
 * dragged elements to be tracked. It also provides the implementation
 * strategy for drag and drop, which, in this case, is the drag-drop
 * mechanism provided by HTML5.
 */
export default TrayComponent;
