Driver = require("./driver").Driver

PI = Math.PI
pow2 = (num) -> Math.pow(num, 2)
sqrt = Math.sqrt

class PlotterRenderer
  constructor: (@plotter) ->

class Plotter
  settings:
    distance: 0 #Distance between pulley centers
    pulleyRadius: 0
    stepsPerRev: 0
    distancePerTurn: 0 #Should be calculated

  state:
    left: 0 #Length of string in working area
    right: 0
    x: 0  #Position of a gandola starting from left pulley center
    y: 0

  path: [] #Points that gandola already went

  constructor: (initialState) ->
    @driver = new Driver()
    @renderer = new PlotterRenderer(this)
    @settings.distancePerTurn = 2 * PI * @settings.pulleyRadius / @settings.stepsPerRev


  draw: (data, virtual=true, phisical=true, speed=1) ->
    @clearState()
    @makeInstructions(data)
    if phisical
      if virtual
        @driver.on 'doStep', =>
          @turnPolley
          @renderer.render()
      @driver.doInstructions @instructions
    else if virtual
      step = 0
      next = =>
        requestAnimationFrame =>
          @turnPolleys @instructions.shift()
          @renderer.render() if step % speed is 0
          step += 1
          next() if @instructions.length > 0

  clearState: ->


  makeInstructions: (relativePath) ->
    state = _.clone @state
    for [dx, dy] in relativePath
      lineEnd = x:state.x + dx, y:state.y + dy
      d = distance state, lineEnd
      return unless d
      samplesNumber = Math.ceil(d) * 2 # This constant should be tweaked

      samples =
        for i in [0..samplesNumber]
          portion = i / samplesNumber
          x: state.x + (lineEnd.x - state.x) * portion
          y: state.y + (lineEnd.y - state.y) * portion

      for sample in samples
        happy = false
        while not happy
          @updateStatePosition state

          calculateTurnsForSide = (origin, side)->
            targetD = distance origin, sample
            currentD = distance origin, state
            distanceDiff = targetD - currentD
            needForStep = Math.abs(distanceDiff) >= @settings.distancePerTurn
            happy = happy and Math.abs(distanceDiff) < @settings.distancePerTurn * 2
            if needForStep
              bigger = distanceDiff > 0
              direction = bigger and 1 or -1
              state[side] += direction * @settings.distancePerTurn
              +bigger
            else
              -1

          happy = true
          instruction = [
            calculateTurnsForSide x: 0, y: 0, 'left'
            calculateTurnsForSide x: @settings.distance, y: 0, 'right'
          ]
          @instructions.push(instruction) if instruction[0] > -1 or instruction[1] > -1

  updateStatePosition: (state) ->
    triangleHeight = (a, b, c) ->
      sqrt((a + b - c) * (a - b + c) * (-a + b + c) * (a + b + c)) / (c * 2)

    hypRealToVirtual = (hypReal) =>
      sqrt pow2(hypReal) + pow2(@settings.pulleyRadius)

    leftCenterDist = hypRealToVirtual state.left
    rightCenterDist = hypRealToVirtual state.right

    y = triangleHeight leftCenterDist, rightCenterDist, @settings.distance
    x = sqrt pow2(leftCenterDist) - pow2(y)

    state.x = x
    state.y = y

#    x2 = sqrt pow2(rightCenterDist) - pow2(y)
#    rollerPosition = (hr, hv, x) ->
#      alpha = Math.asin(hr / hv) + Math.asin(x / hv) - (Math.PI / 2)
#      x: Math.cos(alpha) * @settings.pulleyRadius
#      y: Math.sin(alpha) * @settings.pulleyRadius

#    left:
#      roller: rollerPosition(hr1, leftCenterDist, x1)
#      x: x1
#    right:
#      roller: rollerPosition(hr2, rightCenterDist, x2)
#      x: x2
#    height: y

  turnPolleys: (left, right) ->
    return if left < 0 and right < 0
    @turnPolley('left', left) if left > -1
    @turnPolley('right', right) if right > -1
    @updateStatePosition @state
    @path.push [@state.x, @state.y]

  turnPolley: (side, dir) ->
    mult = if dir is 0 then -1 else 1
    @state[side] += mult * @settings.distancePerTurn



