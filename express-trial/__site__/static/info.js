
var supportsDragAndDrop = function() {
  let div = window.document.createElement('div');
  return ('draggable' in div) || ('ondragstart' in div && 'ondrop' in div);
};

var isTouchDevice = ('ontouchstart' in window) || ((Navigator.maxTouchPoints in Navigator) && (Navigator.maxTouchPoints > 0));

var isMobile = /Mobi/.test(navigator.userAgent);


