/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

export const noMoveError = {
  name: "no moves",
  message: "no moves found for play"
};

export const multiplePlayLinesError = {
  name: "multiple play lines",
  message: "multiple lines in both directions have moves"
};

export const incompleteWordError = {
  name: "incomplete word",
  message: "moves do not result in a single word"
};

export const offCenterError = {
  name: "off-center first play",
  message: "first word of game does not cover the center square"
};

export const disconnectedWordError = {
  name: "disconnected word",
  message: "played word is not connected to existing tiles"
};

export const noAdjacentWordError = {
  name: "no adjacent word",
  message: "no unique adjacent word for word composed entirely of new tiles"
};

