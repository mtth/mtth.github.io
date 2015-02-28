/* jshint node: true */

(function () {
  'use strict';

  var fs = require('fs'),
      gulp = require('gulp'),
      browserify = require('browserify'),
      jade = require('gulp-jade'),
      stylus = require('gulp-stylus');

  var paths = {
    jade: './lib/jade/*.jade',
    js: './lib/js/index.js',
    styl: './lib/styl/*.styl'
  };

  gulp.task('jade', function () {
    gulp.src(paths.jade)
      .pipe(jade())
      .pipe(gulp.dest('./'));
  });

  gulp.task('js', function () {
    // TODO: write equivalent to `vinyl-source-stream`.
    // TODO: make this be run on each JS file independently.
    browserify(paths.js)
      .bundle()
      .pipe(fs.createWriteStream('./public/js/index.js'));
  });

  gulp.task('styl', function () {
    gulp.src(paths.styl)
      .pipe(stylus({compress: true}))
      .pipe(gulp.dest('./public/css'));
  });

  gulp.task('build', ['jade', 'js', 'styl']);

  gulp.task('watch', ['build'], function () {
    var k;
    for (k in paths) {
      gulp.watch(paths[k], [k]);
    }
  });

  gulp.task('default', ['watch']);

})();
