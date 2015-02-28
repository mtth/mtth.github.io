/* jshint browser: true, browserify: true */

(function () {
  'use strict';

  var $ = require('jquery');

  /**
   * Create optimal layout given current viewport height.
   *
   * Basic goal is to have the image attached to the bottom of the screen while
   * keeping enough room at the top to display our title and description.
   *
   */
  function layout() {

    // Our height bounds.
    var minInfoHeight = 225; // Minimum height we require for the text.
    var minImgHeight = 50; // Minimum visible height of the image.
    var maxImgHeight = 300; // Maximum visible height of the image.

    // Basic math!
    var docHeight = $(window).height();
    var imgHeight = Math.max(
      minImgHeight,
      Math.min(maxImgHeight, docHeight - minInfoHeight)
    );
    var infoTopMargin = (docHeight - imgHeight - minInfoHeight) / 2;

    $('#content')
      .css('height', docHeight);

    $('.info')
      .css('margin-top', infoTopMargin)
      .show();

    $('.link')
      .css('bottom', imgHeight - $('img').height());

  }

  $(function () {

    setTimeout(layout, 250);
    // We add a small delay (some browsers seems to report a false height
    // sometimes otherwise).

  });

})();
