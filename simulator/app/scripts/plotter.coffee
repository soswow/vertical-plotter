PI = Math.PI
pow2 = (num) -> Math.pow(num, 2)
sqrt = Math.sqrt


class scope.PlotterRenderer
  plotter: null
  zoom: 1

  constructor: (@canvas) ->
    @ctx = @canvas.getContext '2d'
    @width = @canvas.width
    @height = @canvas.height

  clear: ->
    @canvas.width = @width
    @canvas.height = @height

  scaleFactor: ->
    @width / @plotter.settings.distance

  moveTo: (x, y) -> @ctx.moveTo x * @zoom + 0.5 - @transX, y * @zoom + 0.5 - @transY
  lineTo: (x, y) -> @ctx.lineTo x * @zoom + 0.5 - @transX, y * @zoom + 0.5 - @transY

  drawLine: (x1, y1, x2, y2) ->
    @moveTo x1, y1
    @lineTo x2, y2

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

    @moveTo @plotter.path[0][0], @plotter.path[0][1]
    for [x, y] in @plotter.path[1..]
      @lineTo x, y

    @ctx.stroke()
    @ctx.closePath()

  renderModel: ->

  render: ->
    @clear()
    if @zoom > 1
      @transX = @zoom * @plotter.state.x - @width
      @transY = @zoom * @plotter.state.y - @height
    else
      @transX = 0
      @transY = 0
    @ctx.scale @scaleFactor(), @scaleFactor()
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
    console.log 'Renderer in place' if @renderer?
    console.log 'Driver in place' if @driver?
    @updateSettings(name, value) for name, value of settings if settings
    @state = state if state
    @renderer?.plotter = this

    @turnPolleys(null, null)
    @renderer?.render()

  updateSettings: (name, value) ->
    @settings[name] = value
    if name is 'distance'
      @renderer?.plotter = this
      @turnPolleys(null, null)
      @renderer.render()

    if name in ['pulleyRadius', 'stepsPerRev']
      @settings.distancePerTurn = 2 * PI * @settings.pulleyRadius / @settings.stepsPerRev

  updateState: (side, value) ->
    @state[side] = value
    @turnPolleys(null, null)
    @renderer.render()

  draw: (data, virtual=true, phisical=true) ->
    @clearState()
    @makeInstructions(data)
    f = (n) ->
      return 0 unless n?
      return 1 if n
      return -1 unless n
#    document.getElementById("log").innerText = 'left, right\n' + @instructions.map(([a,b]) -> f(a) + ', ' + f(b)).join("\n")
    phisical = false unless @driver
    virtual = false unless @renderer
    console.log "Drawing on screen:#{virtual}, on board:#{phisical}"

    throw "No madia to draw on!" if not phisical and not virtual

    if phisical
      if virtual
        @driver.on 'doStep', (leftStep, rightStep) =>
          @turnPolleys(leftStep, rightStep)
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
      samplesNumber = Math.ceil(d) * 4 # This constant should be tweaked

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
              bigger
            else
              null

          happy = true
          instruction = [
            calculateTurnsForSide x: 0, y: 0, 'left'
            calculateTurnsForSide x: @settings.distance, y: 0, 'right'
          ]
          @instructions.push(instruction) if instruction[0]? or instruction[1]?

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
    @turnPolley('left', left) if left?
    @turnPolley('right', right) if right?
    @updateStatePosition @state
    @path.push [@state.x, @state.y]

  turnPolley: (side, bigger) ->
    mult = if bigger then 1 else -1
    @state[side] += mult * @settings.distancePerTurn