var path = require('path');
var webpack = require('webpack');

// To be used in testing the complete app. Creates bundle but does not optimize away error reporting.
// TODO. Use source maps with production version.

module.exports = {
  // devtool: 'cheap-module-source-map', // Only 120 bytes in source map!
  devtool: 'source-map', // source map 5 times as big as bundle!
  entry: [
    './src/index'
  ],
  output: {
    path: path.resolve(__dirname, 'dist/static'),
    filename: 'boardgame.bundle.js',
    publicPath: '/static/',
    sourceMapFilename: 'boardgame.js.map'
  },
  plugins: [
    new webpack.LoaderOptionsPlugin({
      minimize: true,
      debug: false
    }),
    new webpack.optimize.UglifyJsPlugin({
      beautify: false,
      mangle: {
        screw_ie8: true,
        keep_fnames: true
      },
      compress: {
        screw_ie8: true
      },
      comments: false,
      sourceMap: true
    })
  ]
  ,
  module: {
    rules: [{
      test: /\.js$/,
      use: ['babel-loader'],
      exclude: /node_modules/,
      include: path.join(__dirname, 'src')
    },
    {
      test: /\.json$/,
      use: "json-loader"
    }
    ]
  }
};
