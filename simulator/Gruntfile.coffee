'use strict';

module.exports = (grunt) ->
  require('time-grunt')(grunt)
  require('load-grunt-tasks')(grunt)

  grunt.initConfig
    yeoman:
      app: 'app'
      dist: 'dist'

    watch:
      coffee:
        files: ['<%= yeoman.app %>/scripts/{,**/}*.{coffee,litcoffee,coffee.md}']
        tasks: ['coffee:dist']
      compass:
        files: ['<%= yeoman.app %>/styles/{,**/}*.{scss,sass}']
        tasks: ['compass:server']
      livereload:
        options:
          livereload: '<%= connect.options.livereload %>'
        files: [
          '<%= yeoman.app %>/*.html'
          '.tmp/styles/{,*/}*.css'
          '{.tmp,<%= yeoman.app %>}/scripts/{,**/}*.js'
          '<%= yeoman.app %>/images/{,**/}*.{gif,jpeg,jpg,png,svg,webp}'
        ]


    connect:
      options:
        port: 9000
        livereload: 35729
      # change this to '0.0.0.0' to access the server from outside
        hostname: 'localhost'

      livereload:
        options:
          open: true
          base: [
            '.tmp'
            '<%= yeoman.app %>'
          ]

      dist:
        options:
          open: true
          base: '<%= yeoman.dist %>'
          livereload: false


    clean:
      dist:
        files: [
          dot: true
          src: [
            '.tmp'
            '<%= yeoman.dist %>/*'
            '!<%= yeoman.dist %>/.git*'
          ]
        ]
      server: '.tmp'
      releases: 'webkitbuilds/releases'


    coffee:
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.app %>/scripts'
          src: '{,**/}*.{coffee,litcoffee,coffee.md}'
          dest: '.tmp/scripts'
          ext: '.js'
        ]


    compass:
      options:
        sassDir: '<%= yeoman.app %>/styles'
        cssDir: '.tmp/styles'
        generatedImagesDir: '.tmp/images/generated'
        imagesDir: '<%= yeoman.app %>/images'
        javascriptsDir: '<%= yeoman.app %>/scripts'
        fontsDir: '<%= yeoman.app %>/styles/fonts'
#        importPath: '<%= yeoman.app %>/bower_components' #Open when needed
        httpImagesPath: '/images'
        httpGeneratedImagesPath: '/images/generated'
        httpFontsPath: '/styles/fonts'
        relativeAssets: false
        assetCacheBuster: false

      dist:
        options:
          generatedImagesDir: '<%= yeoman.dist %>/images/generated'

      server:
        options:
          debugInfo: true


    useminPrepare:
      options:
        dest: '<%= yeoman.dist %>'
      html: '<%= yeoman.app %>/index.html'


    usemin:
      options:
        assetsDirs: ['<%= yeoman.dist %>']
      html: ['<%= yeoman.dist %>/{,*/}*.html']
      css: ['<%= yeoman.dist %>/styles/{,*/}*.css']


    htmlmin:
      dist:
        options: {
          #/*removeCommentsFromCDATA: true,
          #// https://github.com/yeoman/grunt-usemin/issues/44
          #//collapseWhitespace: true,
          #collapseBooleanAttributes: true,
          #removeAttributeQuotes: true,
          #removeRedundantAttributes: true,
          #useShortDoctype: true,
          #removeEmptyAttributes: true,
          #removeOptionalTags: true*/
        }
        files: [
          expand: true
          cwd: '<%= yeoman.app %>'
          src: '*.html'
          dest: '<%= yeoman.dist %>'
        ]


    imagemin:
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.app %>/images'
          src: '{,*/}*.{gif,jpeg,jpg,png}'
          dest: '<%= yeoman.dist %>/images'
        ]


    copy:
      dist:
        files: [{
          expand: true
          dot: true
          cwd: '<%= yeoman.app %>'
          dest: '<%= yeoman.dist %>'
          src: [
            '*.{ico,png,txt}'
            '.htaccess'
            'images/{,*/}*.{webp,gif}'
            'styles/fonts/{,*/}*.*'
            'package.json'
          ]
        },{
          expand: true
          dot: true
          cwd: '.tmp'
          dest: '<%= yeoman.dist %>'
          src: [
            'scripts/node/*.js'
          ]
        }]

    nodewebkit:
      options:
        build_dir: './webkitbuilds' # Where the build version of my node-webkit app is saved
        mac: true
        win: false
        linux32: false
        linux64: false
        keep_nw: true
      src: ['<%= yeoman.dist %>/**/*'] # Your node-wekit app

    concurrent:
      server: [
        'compass'
        'coffee:dist'
      ]
      dist: [
        'coffee'
        'compass'
        'imagemin'
        'htmlmin'
      ]


    grunt.registerTask 'serve', (target) ->
      if target is 'dist'
        grunt.task.run ['build', 'connect:dist:keepalive']
      else
        grunt.task.run [
          'clean:server'
          'concurrent:server'
          'connect:livereload'
          'watch'
        ]

    grunt.registerTask 'build', [
      'clean:dist'
      'useminPrepare'
      'concurrent:dist'
      'concat'
      'cssmin'
      'uglify'
      'copy:dist'
      'usemin'
      'clean:releases'
      'nodewebkit'
    ]