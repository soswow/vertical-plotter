firmata = require('firmata')
Events = require('backbone-events-standalone').BackboneEvents

class Driver
  ready: false
  kill: false

  instructions: []

  constructor: ->
    @pins =
      dir:
        left: 8
        right: 10
      step:
        left: 9
        right: 11
    @usbUrl = '/dev/cu.usbserial-A700ejJW'

    process.on 'SIGINT', =>
      @kill = true
      process.exit()

  initialize: ->
    @board = new firmata.Board @usbUrl, (err) =>
      throw err if err
      @ready = true

      @board.pinMode @pins.dir.left, @board.MODES.OUTPUT
      @board.pinMode @pins.dir.right, @board.MODES.OUTPUT
      @board.pinMode @pins.step.left, @board.MODES.OUTPUT
      @board.pinMode @pins.step.right, @board.MODES.OUTPUT

      @trigger 'ready'

  doInstructions: (@instructions) ->
    start = =>
      @trigger 'start'
      @nextStep()
    if @ready
      start()
    else
      @on 'ready', start

  nextStep: =>
    return unless @ready
    if @instructions.length
      [leftStep, rightStep] = @instructions.shift()
      @doStep('left', leftStep) if leftStep?
      @doStep('right', rightStep) if rightStep?
      @trigger 'doStep', leftStep, rightStep

    setTimeout @nextStep, 10 unless @kill

  doStep: (side, bigger) ->
    dir = switch side
      when 'left'
        if bigger then @board.LOW else @board.HIGH
      when 'right'
        if bigger then @board.HIGH else @board.LOW
    @board.digitalWrite @pins.dir[side],  dir
    @board.digitalWrite @pins.step[side], @board.HIGH
    @board.digitalWrite @pins.step[side], @board.LOW

Events.mixin(Driver::)

exports.Driver = Driver