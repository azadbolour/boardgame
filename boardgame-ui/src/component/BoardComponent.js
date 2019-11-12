/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Board */
import React from 'react';
import PropTypes from 'prop-types';
import BoardSquareComponent from './BoardSquareComponent';
import PieceComponent from './PieceComponent';
// import * as Piece from '../domain/Piece';
import {mkPoint} from '../domain/Point';
import * as Point from '../domain/Point';
// import logger from "../util/Logger";
// import {stringify} from "../util/Logger";

/**
 * A style that includes the board's overall
 * dimensions in pixels, and the layout of its
 * children (the board's squares).
 */
function boardStyle(dimension, squarePixels) {
  let pixels = dimension * squarePixels;
  return {
    width: pixels + 'px',
    height: pixels + 'px',
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
  return { width: pix, height: pix }
}

/**
 * User interface component representing a board.
 */
class BoardComponent extends React.Component {
  static propTypes = {
    /**
     * The board data.
     */
    board: PropTypes.object.isRequired,

    /**
     * Positions that are currently in play by the user - i.e. occupied by pieces.
     */
    pointsInUserPlay: PropTypes.array.isRequired,

    /**
     * Points that were just filled by the machine.
     */
    pointsMovedInMachinePlay: PropTypes.array.isRequired,

    /**
     * Function of position that determines whether the position
     * is a legal destination of a move - whether a piece is allowed
     * to be moved to that position given the current state of the game.
     */
    isLegalMove: PropTypes.func.isRequired,

    canMovePiece: PropTypes.func.isRequired,

    /**
     * The number of pixels used to represent the side of each
     * board square.
     */
    squarePixels: PropTypes.number.isRequired,

    pointValues: PropTypes.object.isRequired,

    /**
     * The board responds to interactions.
     */
    enabled: PropTypes.bool.isRequired,

    gameState: PropTypes.object.isRequired,

    /**
     * Handler of user actions.
     */
    gameEventHandler: PropTypes.object.isRequired
  };

  /**
   * Is an row, col position currently occupied?
   */
  positionInPlay(point) {
    return this.props.pointsInUserPlay.some(p => Point.eq(p, point));
  }

  /**
   * Return the UI specification of the piece that goes into
   * a specific board square - given the square's position.
   */
  renderPiece(point) {
    let piece = this.props.board.rows()[point.row][point.col].piece;
    let canMovePiece = this.props.canMovePiece;
    let enabled = this.props.enabled;
    // piece = (piece) ? piece : Piece.NO_PIECE;
    return <PieceComponent
      piece={piece}
      canMovePiece={canMovePiece}
      enabled={enabled}
    />;
  }

  /**
   * Return the UI specification of a single square based
   * on it row, col coordinates.
   *
   * A function may return the react specification of a
   * UI component, and these specifications may be composed.
   */
  renderSquare(row, col) {
    let gameState = this.props.gameState;
    let gameEventHandler = this.props.gameEventHandler;
    let dimension = this.props.board.dimension;
    let squareKey = dimension * row + col;
    let isLegalMove = this.props.isLegalMove;
    let squarePixels = this.props.squarePixels;
    let point = mkPoint(row, col);
    let inPlay = this.props.pointsInUserPlay.some(p => Point.eq(p, point));
    let justFilledByMachine = this.props.pointsMovedInMachinePlay.some(p => Point.eq(p, point));
    let enabled = this.props.enabled;
    let pointValue = this.props.pointValues.getElement(point);
    // let center = Math.floor(dimension/20);
    // let isCenterPoint = row === center && col === center;
    let squarePiece = this.props.board.rows()[row][col].piece;

    return (
      <div key={squareKey} style={squareStyle({squarePixels})}>
        <BoardSquareComponent
          inPlay={inPlay}
          justFilledByMachine={justFilledByMachine}
          point={point}
          piece={squarePiece}
          isLegalMove={isLegalMove}
          squarePixels={squarePixels}
          pointValue={pointValue}
          enabled={enabled}
          gameState={gameState}
          gameEventHandler={gameEventHandler}
        >
            {this.renderPiece(point)}
        </BoardSquareComponent>
      </div>
    );
  }

  /**
   * Render all the squares on the board by accumulating their
   * component objects in an array and interpolating the array as
   * the child of a div component. The div component has a style
   * with the correct overall size of the board.
   */
  render() {
    let dimension = this.props.board.dimension;
    let squarePixels = this.props.squarePixels;
    let squares = [];
    for (let row = 0; row < dimension; row++)
      for (let col = 0; col < dimension; col++)
        squares.push(this.renderSquare(row, col));

    return (
      <div style={boardStyle(dimension, squarePixels)}>
        {squares}
      </div>
    );
  }
}

export default BoardComponent;
