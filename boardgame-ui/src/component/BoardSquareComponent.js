/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module BoardSquare */

import React from 'react';
import PropTypes from 'prop-types';
import SquareComponent from './SquareComponent';
import actions from '../event/GameActions';
import GameActionTypes from '../event/GameActionTypes';
import * as Piece from '../domain/Piece';
import {mkPiece} from '../domain/Piece';
// import {mkPoint} from '../domain/Point';
import {mkPiecePoint} from '../domain/PiecePoint';
// import {stringify} from "../util/Logger";
import {pieceIsDead} from "../domain/Piece";
const ItemTypes = require('./DragDropTypes').ItemTypes;
const DropTarget = require('react-dnd').DropTarget;

/**
 * Color coding style for move destinations (drop targets of the the piece being dragged).
 * It style is absolute w.r.t. to its parent (the board square), and its dimensions
 * are the same as the board square so it covers the same area as the board square.
 */
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
 * The style for indicating that a piece on the board has been moved
 * during the current play - is in the current play but not yet committed.
 */
function inPlayStyle() {
  const pix = '6px';
  return {
    position: 'absolute',
    top: 1,
    left: 1,
    height: pix,
    width: pix,
    zIndex: 1,
    color: 'white',
    backgroundColor: 'GoldenRod'
  };
}

function justFilledByMachineStyle() {
  const pix = '6px';
  return {
    position: 'absolute',
    top: 1,
    left: 1,
    height: pix,
    width: pix,
    zIndex: 1,
    color: 'white',
    backgroundColor: 'YellowGreen'
  };
}

function scoreStyle(pointValue, squarePixels) {
  const height = 10;
  const width = Math.floor(squarePixels/2);
  let backgroundColor = pointValueColor(pointValue);
  let top = squarePixels - height;
  // let top = 0;
  // let left = squarePixels - width;
  let left = 1;
  return {
    position: 'absolute',
    top: top,
    left: left,
    height: height + 'px',
    width: width + 'px',
    zIndex: 1,
    color: 'Black',
    backgroundColor: backgroundColor,
    opacity: 1,
    fontSize: 10,
    textAlign: 'center',
    MozUserSelect: 'none',
    WebkitUserSelect: 'none',
    MsUserSelect: 'none',
    userSelect: 'none'
  };
}

/**
 * Style for the square - it is relative to its siblings within its parent.
 */
function squareStyle(pixels) {
  let pix = pixels + 'px';
  return {
    position: 'relative',
    width: pix,
    height: pix
  };
}

let getMonitorPiece = function(monitor) {
  let pieceItem = monitor.getItem();
  return mkPiece(pieceItem.value, pieceItem.id);
};

const MIN_MOVEMENT = 15;

const vectorMagnitude = (x, y) => Math.sqrt(x ** 2 + y ** 2);
const isMinimallyMoved = ({ x, y }) => vectorMagnitude(x, y) > MIN_MOVEMENT;

/**
 * An object that tells the react DnD framework how to drop
 * a dragged item. This object is given as a parameter
 * to the DropTarget decorator (see export below).
 *
 * The props in the callback methods of this object are the props
 * of drop target component - the component that is a candidate
 * for a possible drop.
 *
 * In this case the props are the props of the board square that
 * is a possible destination of a drop of a piece.
 *
 * The monitor in the callback methods provides information about what
 * is being dragged. Its getItem method returns the item provided by
 * the drag source. In this case, the drag source is a Piece,
 * and as a drag source it has a corresponding pieceDragger whose
 * beginDrag method returns the "drag source" item, which the
 * monitor's "getItem" method returns.
 *
 * See the React documentation for the API of drop targets.
 */
const pieceDropper = {
  canDrop: function (props, monitor) {
    let piece = getMonitorPiece(monitor);
    let point = props.point;
    let legal = props.isLegalMove(piece, point);
    // A workaround to avoid react dnd glitch preventing drag.
    let minimallyMoved = isMinimallyMoved((monitor.getDifferenceFromInitialOffset()));
    return minimallyMoved && legal && props.enabled;
  },

  drop: function (props, monitor) {
    let piece = getMonitorPiece(monitor);
    let point = props.point;
    let move = mkPiecePoint(piece, point);
    // actions.move(move);
    props.dispatch({
      type: GameActionTypes.MOVE,
      move: move
    });
  }
};

/**
 * A function that tells the react dnd framework what drag and drop
 * properties to inject into objects that are subject to drag and drop
 * context - I guess the descendants of a component decorated
 * as a drag drop context. This is called a 'collect' function in
 * the react dnd jargon. It is given as a parameter to the drop target
 * decorator (see export below).
 *
 * @param connect - see React DND docs.
 * @param monitor DropTargetMonitor - see React DND docs.
 */
function injectedDropTargetProperties(connect, monitor) {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver(),
    canDrop: monitor.canDrop()
  };
}

/**
 * Get the shade of the checker at the given position - light or dark square.
 */
// function checkerShade(point) {
//   return (point.row + point.col) % 2 === 0 ? 'light' : 'dark'; // TODO. Constants.
// }

function pointValueColor(pointValue) {
  let defaultColor = 'CornSilk';
  switch (pointValue) {
    case 1: return defaultColor;
    case 2: return 'Aquamarine';
    case 3: return 'Aqua';
    case 4: return 'Gold';
    case 5: return 'GoldenRod';
    default :
      return defaultColor;
  }
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
class BoardSquareComponent extends React.Component {
  static propTypes = {
    /**
     * The position of the square on the board.
     */
    point: PropTypes.shape({
      row: PropTypes.number.isRequired,
      col: PropTypes.number.isRequired
    }).isRequired,

    /**
     * The piece being rendered. For now this is just for the purpose of
     * optimization - to check if the piece has changed in shouldComponentRender.
     * The piece is part of the children hierarchy and will be rendered automatically.
     * This is to make performance on phones acceptable for now.
     * With the introduction of dead cells, the piece is also used
     * to determine if the current square is dead.
     */
    piece: PropTypes.object.isRequired,

    /**
     * The number of pixels in each side of the square.
     */
    squarePixels: PropTypes.number.isRequired,

    pointValue: PropTypes.number.isRequired,

    /**
     * Does this square form part of the current play?
     * That is, has a piece been moved to this square during
     * the currently ongoing play, but the play has not
     * been committed yet?
     */
    inPlay: PropTypes.bool.isRequired,

    /**
     * This square was just filled by machine. Used to highlight the machine play.
     */
    justFilledByMachine: PropTypes.bool.isRequired,

    /**
     * Is the cursor over the current square?
     */
    isOver: PropTypes.bool.isRequired,

    /**
     * Is it legal to drop the current piece being dragged onto
     * this square?
     */
    isLegalMove: PropTypes.func.isRequired,

    canDrop: PropTypes.bool.isRequired,

    /**
     * Responds to user interactions.
     */
    enabled: PropTypes.bool.isRequired,

    /**
     * Redux dispatcher.
     */
    dispatch: PropTypes.func.isRequired

    // Note connectDropTarget is also injected.
  };

  shouldComponentUpdate(nextProps, nextState) {
    let inPlayDiff = nextProps.inPlay !== this.props.inPlay;
    let justFilledByMachineDiff = nextProps.justFilledByMachine !== this.props.justFilledByMachine;
    let valueDiff = nextProps.pointValue !== this.props.pointValue;
    let overDiff = nextProps.isOver !== this.props.isOver;
    let dropDiff = nextProps.canDrop !== this.props.canDrop;
    let pieceDiff = !Piece.eq(nextProps.piece, this.props.piece);
    return inPlayDiff || justFilledByMachineDiff || valueDiff || overDiff || dropDiff || pieceDiff;
  };

  render() {
    let connectDropTarget = this.props.connectDropTarget;
    let isOver = this.props.isOver;
    let canDrop = this.props.canDrop;
    // let shade = checkerShade(this.props.point);
    let pixels = this.props.squarePixels;
    let inPlay = this.props.inPlay;
    let justFilledByMachine = this.props.justFilledByMachine;
    let pointValue = this.props.pointValue;
    let dead = pieceIsDead(this.props.piece);

    // let isLight = (shade === 'light'); // TODO. Constant.
    // let backgroundColor = isLight ? 'CornSilk' : 'AquaMarine';
    let backgroundColor = pointValueColor(pointValue);
    if (dead)
      backgroundColor = "Gainsboro";
    let color = 'FireBrick';
    // let color = 'Tomato';
    // let isCenterPoint = this.props.isCenterPoint;
    let enabled = this.props.enabled;

    return connectDropTarget(
      <div style={squareStyle(pixels)}>

        <SquareComponent
          pixels={pixels}
          color={color}
          backgroundColor={backgroundColor}
          enabled={enabled}>
          {this.props.children}
        </SquareComponent>

        {isOver && !canDrop && <div style={colorCodedLegalMoveStyle(pixels, 'red')} />}
        {isOver && canDrop && <div style={colorCodedLegalMoveStyle(pixels, 'green')} />}
        {inPlay && <div style={inPlayStyle()} />}
        {justFilledByMachine && <div style={justFilledByMachineStyle()} />}
        {!dead &&
          <div style={scoreStyle(pointValue, pixels)}>
            {pointValue}
          </div>
        }
      </div>
    );
  }
}

/**
 * Decorator of the BoardSquare as a drop target.
 *
 * The item type says which type of item can be dropped on the
 * given component.
 *
 * The piece dropper is called back to find out if it is legal
 * to drop an item on the given component, and to trigger the
 * required action to be performed on a drop.
 *
 * The injected drop target properties is called back to get
 * an associative array of the properties to be injected into
 * the drop target - the board square in this case.
 */

export default DropTarget(ItemTypes.PIECE, pieceDropper, injectedDropTargetProperties)(BoardSquareComponent);

