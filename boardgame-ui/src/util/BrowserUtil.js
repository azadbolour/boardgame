/*
 * Copyright 2017-2018 Azad Bolour
 * Licensed under GNU Affero General Public License v3.0 -
 *   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
 */

import detectIt from 'detect-it';
import {queryParams} from './UrlUtil';
import AppParams from './AppParams';

export const hasDragAndDrop = function() {
  let div = window.document.createElement('div');
  return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
};

// Obsolete legacy checks.
// export const isTouchDevice = ('ontouchstart' in window) || ((Navigator.maxTouchPoints in Navigator) && (Navigator.maxTouchPoints > 0));
// export const isMobile = /Mobi/.test(navigator.userAgent);

// export const usingMouse = function() {
//   let preferred = getPreferredInputDevice();
//   let inputDevice = pointingDevice(preferred);
//   return inputDevice === mouse;
// };
//
// export const usingTouch = function() {
//   let preferred = getPreferredInputDevice();
//   let inputDevice = pointingDevice(preferred);
//   return inputDevice === touch;
// };

/**
 * Get the name of the pointing device to use.
 * @param preferredDevice The user's preferred device ('mouse' or 'touch') -
 *    returned if available in current browser.
 * @returns 'mouse' or 'touch' or undefined.
 */
export const inputDeviceInfo = function() {
  let primaryDevice = detectPrimaryDevice();

  // TODO. Constant used also in index.js. Should be defined in AppParams.
  let preferredDevice = queryParams(window.location).getParam("preferred-input-device");

  const unavailableResponse = {
    device: primaryDevice,
    message: `preferred device '${preferredDevice}' is unavailable`
  };

  const availableResponse = function(device) {
    return {device};
  };

  // No preference specified.
  if (preferredDevice === undefined)
    return availableResponse(primaryDevice);

  let {valid: preferredDeviceIsValid} = AppParams.validatePreferredInputDevice(preferredDevice);

  // Preference is invalid
  if (!preferredDeviceIsValid)
    return unavailableResponse;

  // Preference is valid and available.
  if (isDeviceAvailable(preferredDevice))
    return availableResponse(preferredDevice);

  // Preference is valid but unavailable.
  return unavailableResponse;
};

function isDeviceAvailable(deviceName) {
  if (deviceName === undefined)
    return false;

  switch (deviceName) {
    case AppParams.MOUSE_INPUT:
      return detectIt.hasMouse || (detectIt.primaryInput === AppParams.MOUSE_INPUT);
    case AppParams.TOUCH_INPUT:
      return detectIt.hasTouch || (detectIt.primaryInput === AppParams.TOUCH_INPUT);
    default:
      return false;
  }
}

/**
 * If no primary input is detectable then default to mouse if available,
 * otherwise to touch if available.
 */
function detectPrimaryDevice() {
  let primary = detectIt.primaryInput;
  if (AppParams.INPUT_DEVICES.includes(primary))
    return primary;
  if (detectIt.hasMouse)
    return AppParams.MOUSE_INPUT;
  if (detectIt.hasTouch)
    return AppParams.MOUSE_INPUT;
  return AppParams.MOUSE_INPUT; // For good measure.
}
