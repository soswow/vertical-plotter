PI = Math.PI
pow2 = (num) -> Math.pow(num, 2)
sqrt = Math.sqrt


class scope.PlotterRenderer
  plotter: null

  constructor: (@canvas) ->
    @ctx = @canvas.getContext '2d'

  clear: ->
    @canvas.width = @canvas.width

  setPlotter: (@plotter) ->
    @scaleFactor = @canvas.width / @plotter.settings.distance

  drawLine: (x1, y1, x2, y2) ->
#    console.log x1, y1, x2, y2
    @ctx.moveTo x1 + 0.5, y1 + 0.5
    @ctx.lineTo x2 + 0.5, y2 + 0.5

  renderStrings: ->
    @ctx.beginPath()
    @ctx.lineWidth = 2
    @ctx.strokeStyle = 'black'

    @drawLine 0, 0, @plotter.state.x, @plotter.state.y
    @drawLine @plotter.settings.distance, 0, @plotter.state.x, @plotter.state.y

    @ctx.stroke()
    @ctx.closePath()

  renderPath: ->
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = '#ccc'

    @ctx.moveTo @plotter.path[0][0] + 0.5, @plotter.path[0][1] + 0.5
    for [x, y] in @plotter.path[1..]
      @ctx.lineTo x + 0.5, y + 0.5

    @ctx.stroke()
    @ctx.closePath()

  renderModel: ->

  render: ->
    @clear()
    @ctx.scale @scaleFactor, @scaleFactor
    @renderPath() if @plotter.path?
    @renderStrings()



class scope.Plotter
  settings:
    distance: 0 #Distance between pulley centers
    pulleyRadius: 0
    stepsPerRev: 0
    virtualSpeed: 1
    distancePerTurn: 0 #Should be calculated

  state:
    left: 0 #Length of string in working area
    right: 0
    x: 0  #Position of a gandola starting from left pulley center
    y: 0

  path: [] #Points that gandola already went

  constructor: (@renderer, @driver, settings=null, state=null) ->
    @updateSettings(name, value) for name, value of settings if settings
    @state = state if state
    @renderer?.setPlotter this

    @turnPolleys(-1, -1)
    @renderer?.render()

  updateSettings: (name, value) ->
    @settings[name] = value
    if name is 'distance'
      @renderer?.setPlotter this
      @turnPolleys(-1, -1)
      @renderer.render()

    if name in ['pulleyRadius', 'stepsPerRev']
      @settings.distancePerTurn = 2 * PI * @settings.pulleyRadius / @settings.stepsPerRev

  updateState: (side, value) ->
    @state[side] = value
    @turnPolleys(-1, -1)
    @renderer.render()

  draw: (data, virtual=true, phisical=true) ->
    @clearState()
    @makeInstructions(data)
    phisical = false unless @driver
    virtual = false unless @renderer

    throw "No madia to draw on!" if not phisical and not virtual

    if phisical
      if virtual
        @driver.on 'doStep', (side, dir) =>
          #TODO turn polleys
#          @turnPolleys
          @renderer.render()
        @driver.doInstructions @instructions
    else if virtual
      step = -1
      makeStep = =>
        nextInstruction = @instructions.shift()
        @turnPolleys.apply this, nextInstruction
        step += 1
        if step % @settings.virtualSpeed is 0
          requestAnimationFrame =>
            @renderer.render()
            makeStep() if @instructions.length > 0
        else
          makeStep() if @instructions.length > 0
      makeStep()

  clearState: -> #TODO

  makeInstructions: (relativePath) ->
    #TODO move this kind of functions somewhere else
    distance = ({x: x1, y: y1}, {x: x2, y: y2}) ->
      Math.sqrt pow2(x1 - x2) + pow2(y1 - y2)

    @instructions = []

    state = _.clone @state
    for [dx, dy] in relativePath
      lineEnd = x:state.x + dx, y:state.y + dy
      d = distance state, lineEnd
      continue unless d
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

          calculateTurnsForSide = (origin, side) =>
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
    @turnPolley('left', left) if left > -1
    @turnPolley('right', right) if right > -1
    @updateStatePosition @state
    @path.push [@state.x, @state.y]

  turnPolley: (side, dir) ->
    mult = if dir is 0 then -1 else 1
    @state[side] += mult * @settings.distancePerTurn