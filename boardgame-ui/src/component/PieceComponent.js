/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Piece */

import React from 'react';
import PropTypes from 'prop-types';
import { useDrag } from 'react-dnd';
// import logger from "../util/Logger";
// import {stringify} from "../util/Logger";
// import * as Piece from "../domain/Piece";
import {isDead} from "../domain/Piece";
const ItemTypes = require('./DragDropTypes').ItemTypes;
// const DragSource = require('react-dnd').DragSource;

const letterStyle = {
  fontSize: 15,
  MozUserSelect: 'none',
  WebkitUserSelect: 'none',
  MsUserSelect: 'none',
  userSelect: 'none'
};

// const pieceDragger = {
//   /**
//    * Return the drag item: an arbitrary plain JS object
//    * providing information about the dragged element.
//    * The drag item is distinct from the source component
//    * of the drag.
//    */
//   beginDrag: function (props) {
//     let piece = props.piece;
//     // console.log(`begin drag: ${stringify(piece)}`);
//     // Must return a plain object.
//     let item = {
//       value: piece.value,
//       id: piece.id,
//     };
//     return item;
//   },
//
//   canDrag(props, monitor) {
//     let can = props.canMovePiece(props.piece);
//     // console.log(`canDrag: ${can} - ${stringify(props.piece)}`);
//     return can;
//   },
//
//   endDrag: function(props, monitor, component) {
//      // console.log(`end drag - dropped: ${monitor.didDrop()}`);
//   }
// };

/**
 * Get dnd properties to be injected into the drag source component.
 * This is called a 'collect' function in the react dnd jargon.
 *
 * @param connect DragSourceConnector - see React dnd docs.
 * @param monitor DragSourceMonitor - see React dnd docs.
 * @returns Plain object including properties to inject into
 * the dragged source component.
 */
// function injectedDragSourceProperties(connect, monitor) {
//   return {
//     connectDragSource: connect.dragSource(),
//     connectDragPreview: connect.dragPreview(),
//     isDragging: monitor.isDragging()
//   }
// }

/**
 * The piece. A draggable item.
 */
const PieceComponent = (props) => {

  const piece = props.piece;
  const draggedItem = {
    type: ItemTypes.PIECE,
    value: piece.value,
    id: piece.id,
  };

  const [{isDragging}, drag] = useDrag({
    item: draggedItem,
    collect: monitor => ({
      isDragging: !!monitor.isDragging(),
    }),
  });

  // let connectDragSource = props.connectDragSource;
  // let connectDragPreview = props.connectDragPreview;
  // let isDragging = props.isDragging;
  let letter = props.piece.value;
  if (isDead(letter))
    letter = ""; // Do not render "dead" piece.
  // let worth = Piece.worths[letter];

  let theDiv =
    <div
      ref={drag}
      style={{
        opacity: isDragging ? 0.5 : 1,
        fontSize: 15,
        fontWeight: 'bold',
        cursor: 'move',
        zIndex: 10
      }}
    >
      <div style={letterStyle}>
        {letter}
      </div>
    </div>;

  return theDiv;

  // if (!isDragging)
  //   return connectDragSource(theDiv);
  // else
  //   return connectDragPreview(connectDragSource(theDiv));
  //   // return connectDragPreview(theDiv);
};


PieceComponent.propTypes = {

  /**
   * The immutable state of the piece.
   * TODO. How to add isRequired with type constraint?
   */
  piece: PropTypes.object.isRequired,

  /**
   * Function that takes a piece and determines if it can be moved
   * (based on its current location and move status).
   */
  canMovePiece: PropTypes.func.isRequired,

  /**
   * Injected - obtained from the 'collect' function.
   */
  // connectDragSource: PropTypes.func.isRequired,

  // connectDragPreview: PropTypes.func.isRequired,

  /**
   * Injected - obtained from the 'collect' function.
   */
  // isDragging: PropTypes.bool.isRequired
};

export default PieceComponent;

// export default DragSource(ItemTypes.PIECE, pieceDragger, injectedDragSourceProperties)(PieceComponent);

// export {PieceComponent as OriginalPieceComponent};
