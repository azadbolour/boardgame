/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

/** @module Game */

// import detectIt from 'detect-it';
import PropTypes from 'prop-types';
import { default as TouchBackend } from 'react-dnd-touch-backend';
import React from 'react';
import ReactList from 'react-list';
import * as Game from '../domain/Game';
import TrayComponent from './TrayComponent';
import BoardComponent from './BoardComponent';
import SwapBinComponent from './SwapBinComponent';
import actions from '../event/GameActions';
// import {stringify} from "../util/Logger";
import * as Style from "../util/StyleUtil";
import * as BrowserUtil from "../util/BrowserUtil";
import AppParams from '../util/AppParams';
import GameParams from '../domain/GameParams';
import { DndProvider } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'
import {stringify} from "../util/Logger";
// const DragDropContext = require('react-dnd').DragDropContext;
// const HTML5Backend = require('react-dnd-html5-backend');



function buttonStyle(enabled) {
  let color = enabled ? 'Chocolate' : Style.disabledColor;
  let backgroundColor = enabled ? 'Khaki' : Style.disabledBackgroundColor;
   return {
    width: '80px',
    height: '60px',
    color: color,
    backgroundColor: backgroundColor,
    align: 'left',
    fontSize: 15,
    fontWeight: 'bold',
    borderWidth: '4px',
    margin: 'auto',
    padding: '2px'
  }
}

const paddingStyle = {
  padding: '10px'
};

const labelStyle = {
  color: 'Brown',
  align: 'left',
  fontSize: 18,
  fontFamily: 'Arial',
  fontWeight: 'bold',
  margin: 'auto',
  padding: '2px'
};

const statusStyle = {
  color: 'Red',
  backgroundColor: 'LightYellow',
  align: 'left',
  fontSize: 16,
  fontWeight: 'bold',
  letterSpacing: '1px',
  margin: '10px',
  padding: '5px',
  minWidth: '500px',
  maxWidth: '500px'
};

const scoreStyle = {
  color: 'Red',
  backgroundColor: 'LightYellow',
  align: 'left',
  fontSize: 16,
  fontWeight: 'bold',
  letterSpacing: '1px',
  margin: 'auto',
  padding: '1px'
};

const lightMessageStyle = function(visible) {
  let display = visible ? 'inline' : 'none';
  return {
    color: 'Maroon',
    align: 'left',
    fontFamily: 'Arial',
    fontSize: 15,
    letterSpacing: '0.5px',
    display: display
  }
};

const tooltipStyle = function(visible) {
  let visibility = visible ? 'visible' : 'hidden';
  let display = visible ? 'inline' : 'none';
  return {
    visibility: visibility,
    display: display,
    width: '150px',
    backgroundColor: 'Khaki',
    color: 'Red',
    fontFamily: 'Arial',
    fontSize: 18,
    textAlign: 'left',
    padding: '5px',
    borderRadius: '6px',
    position: 'absolute',
    zIndex: 1
  }
};

const wordListStyle = {
  overflow: 'auto',
  minHeight: 25,
  maxHeight: 200,
  borderStyle: 'solid',
  borderWidth: '3px',
  borderColor: 'DarkGrey',
  backgroundColor: 'Khaki',
  padding: '4px'
};

const navbarStyle = {
    display: 'flex',
    flexDirection: 'column',
    borderStyle: 'solid',
    borderWidth: '5px',
    padding: '1px',
    backgroundColor: 'Wheat',
    color: 'Wheat'
};

const START = "start";
// const END = "end";
const COMMIT = "commit";
const REVERT = "revert";

let {device, message: deviceSelectionMessage} = BrowserUtil.inputDeviceInfo();
let deviceMessage = [`input device: ${device}`, deviceSelectionMessage].filter(s => s).join(', ');
let displayDeviceMessage = true;
const dndBackend = device === AppParams.TOUCH_INPUT ? TouchBackend : HTML5Backend;

/**
 * The entire game UI component including the board and game buttons.
 */
class GameComponent extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      tipButton: ''
    }
  }

  static propTypes = {
    /**
     * The contents of the grid. It is a 2-dimensional array of strings.
     */
    gameState: PropTypes.object.isRequired,
    gameEventHandler: PropTypes.object.isRequired,
    serverType: PropTypes.string.isRequired
  };

  game() {
    return this.props.gameState.game;
  }

  auxGameData() {
    const auxGameData = this.props.gameState.auxGameData;
    console.log(`GameComponent - auxGameData: ${stringify(auxGameData)}`);
    return auxGameData;
  }

  status() {
    return this.props.gameState.opStatus;
  }

  // TODO. Can we use the other properties of gameState?

  tipOn(tipButton) {
    this.setState({tipButton: tipButton});
  }

  tipOff() {
    this.setState({tipButton: ''});
  }

  isTipOn(tipButton) {
    return this.state.tipButton === tipButton;
  }

  overStart() {

  }

  commitPlay() {
    this.props.gameEventHandler.commitPlayAndGetMachinePlay(this.game(), this.auxGameData());
  }

  revertPlay() {
    this.props.gameEventHandler.revertPlay(this.game(), this.auxGameData());
  }

  /**
   * Eventually game params should be provided in the user interface
   * for starting a new game. For now, it remains the same
   * except for the starting player.
   */
  getNewGameParams(game) {
    let gameParams = game.gameParams;
    // Special-case the very first game for testing.
    if (game.isEmpty() && gameParams.startingPlayer !== undefined)
      return gameParams;
    // Otherwise choose a random starting player.
    let newParams = Object.assign(Object.create(gameParams), gameParams);
    newParams.startingPlayer = GameParams.randomStartingPlayer();
    return newParams;
  }

  startGame() {
    displayDeviceMessage = false;
    let newGameParams = this.getNewGameParams(this.game());
    this.props.gameEventHandler.start(newGameParams);
  }

  renderWord(index, key) {
    let words = this.auxGameData().wordsPlayed;
    let l = words.length;
    let word = words[index].word;
    let wordRep = word.length > 0 ? word : '-----';
    let color = index === l - 1 ? 'FireBrick' : 'Chocolate';
    let backgroundColor = (index % 2) === 0 ? 'LemonChiffon' : 'Gold';
    return <div key={key}
                style={{
                  color: color,
                  backgroundColor: backgroundColor,
                  padding: '3px'
                  }}>{wordRep}</div>;
  }

  scrollToLastWord() {
    this.wordReactListComponent.scrollTo(this.auxGameData().wordsPlayed.length - 1);
  }

  componentDidMount() {
    this.scrollToLastWord();
  }

  componentDidUpdate(prevPros, prevState) {
    this.scrollToLastWord();
  }

  startAttrs = {
    name: START,
    label: "Start",
    toolTip: "start a new game",
    action: () => this.startGame()
  };

  commitAttrs = {
    name: COMMIT,
    label: "Commit Play",
    toolTip: "commit the moves in current play",
    action: () => this.commitPlay()
  };

  revertAttrs = {
    name: REVERT,
    label: "Revert Play",
    toolTip: "revert the moves of the current play",
    action: () => this.revertPlay()
  };

  renderButton(attrs, enabled) {
    return (
      <div style={paddingStyle}>
        <button
          onClick={() => {this.tipOff(); attrs.action()}}
          onMouseOver={() => this.tipOn(attrs.name)}
          onMouseOut={() => this.tipOff()}
          style={buttonStyle(enabled)}
          disabled={!enabled}
        >
          {attrs.label}
        </button>
        {enabled && this.isTipOn(attrs.name) &&
        <div style={tooltipStyle(enabled)}>{attrs.toolTip}</div>
        }
      </div>
    );
  }

  renderScore(player, score) {
    return (
      <div>
        <label style={labelStyle}>{player}: </label>
        <label style={scoreStyle}>{score}</label>
      </div>

    );
  }

  render() {
    let gameState = this.props.gameState;
    let gameEventHandler = this.props.gameEventHandler;
    let game = this.game();
    let auxGameData = this.auxGameData();
    console.log(`GameComponent.render - auxGameData: ${stringify(auxGameData)}`);
    let running = game.running();
    let hasUncommittedPieces = game.numPiecesInPlay() > 0;
    let canMovePiece = game.canMovePiece.bind(game);
    let board = game.board;
    let trayPieces = game.tray.pieces;
    let squarePixels = game.squarePixels;
    let pointsInUserPlay = board.getUserMovePlayPieces().map(pp => pp.point);
    let isLegalMove = game.legalMove.bind(game);
    let status = this.status();
    let serverType = this.props.serverType;
    let userName = game.gameParams.appParams.userName;
    let userScore = game.score[Game.USER_INDEX];
    let machineScore = game.score[Game.MACHINE_INDEX];
    let isTrayPiece = game.tray.isTrayPiece.bind(game.tray);
    // let isError = (status !== "OK" && status !== "game over"); // TODO. This is a hack! Better indication of error and severity.
    // TODO. Fatal error should end the session. Indicate fatal errors.
    let pointValues = game.pointValues;
    let machineMovePoints = game.machineMoves.map(piecePoint => piecePoint.point);
    let productInfo = `Powered by ${serverType} server, React client.`;

    /*
     * Note. Do not use &nbsp; for spaces in JSX. It sometimes
     * comes out as circumflex A (for example in some cases
     * with the Haskell Servant web server). Have not been
     * able to figure why and in what contexts, or how much
     * of it is a React issue and how much Servant.
     *
     * Use <pre> </pre> for spaces instead.
    */

    let startButton = this.renderButton(this.startAttrs, !running);
    let commitButton = this.renderButton(this.commitAttrs, running && hasUncommittedPieces);
    let revertButton = this.renderButton(this.revertAttrs, running && hasUncommittedPieces);

    let trayComponent = <TrayComponent
      pieces={trayPieces}
      canMovePiece={canMovePiece}
      squarePixels={squarePixels}
      enabled={running}
      gameState={gameState}
      gameEventHandler={gameEventHandler}
    />;

    let boardComponent = <BoardComponent
      board={board}
      pointsInUserPlay={pointsInUserPlay}
      pointsMovedInMachinePlay={machineMovePoints}
      isLegalMove={isLegalMove}
      canMovePiece={canMovePiece}
      squarePixels={squarePixels}
      pointValues={pointValues}
      enabled={running}
      gameState={gameState}
      gameEventHandler={gameEventHandler}
    />;

    return (
      <DndProvider backend={dndBackend}>
      <div style={{display: 'flex', flexDirection: 'column'}}>

        <div style={{border: '1px solid GoldenRod', padding: '10px', display: 'inline-block'}}>

          <div style={{display: 'flex', flexDirection: 'row'}}>
            <div style={navbarStyle}>
              {startButton} <pre></pre>
              {commitButton} <pre></pre>
              {revertButton}
              <pre>  </pre>
              <div style={{padding: '15px'}}>
                {this.renderScore(userName, userScore)}
                {this.renderScore("Bot", machineScore)}
              </div>
            </div> <pre>  </pre>
            <div style={{display: 'flex', flexDirection: 'column'}}>
              {trayComponent} <pre></pre>
              {boardComponent}
            </div> <pre>  </pre>
            <div style={{display: 'flex', flexDirection: 'column'}}>
              <div style={paddingStyle}>
                <SwapBinComponent
                  isTrayPiece={isTrayPiece}
                  enabled={running}
                  gameState={gameState}
                  gameEventHandler={gameEventHandler}
                />
              </div>
              <pre> </pre>
              <div>
                <div style={wordListStyle}>
                  <ReactList
                    ref={c => this.wordReactListComponent = c}
                    itemRenderer={ (index, key) => this.renderWord(index, key) }
                    length={auxGameData.wordsPlayed.length}
                    type='uniform'
                  />
                </div>
              </div>
            </div>
          </div>

          <div style={statusStyle}>
            {status}
          </div>


          <div style={{padding: '10px'}}>
            <label style={lightMessageStyle(displayDeviceMessage)}>{deviceMessage}</label>
          </div>

        </div>

        <div style={{paddingTop: '10px'}}>
          <label style={lightMessageStyle(true)}>Copyright 2017-2018 Azad Bolour.</label>
        </div>
        <div style={{paddingTop: '2px'}}>
          <label style={lightMessageStyle(true)}>{productInfo}</label>
        </div>
      </div>
      </DndProvider>
    )
  }
}

// export default DragDropContext(dndBackend)(GameComponent);
export default GameComponent
