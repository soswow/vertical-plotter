pow2 = (num) -> Math.pow(num, 2)
sqrt = Math.sqrt
PI = Math.PI

hypRealToVirtual = (hypReal, radius) ->
  sqrt pow2(hypReal) + pow2(radius)

triangleHeight = (a, b, c) ->
  sqrt((a + b - c) * (a - b + c) * (-a + b + c) * (a + b + c)) / (c * 2)

realHypStartPositions = (hr1, hr2, d, radius) ->
  hv1 = hypRealToVirtual hr1, radius
  hv2 = hypRealToVirtual hr2, radius

  y = triangleHeight(hv1, hv2, d)
  x1 = sqrt pow2(hv1) - pow2(y)
  x2 = sqrt pow2(hv2) - pow2(y)

  rollerPosition = (hr, hv, x) ->
    alpha = Math.asin(hr / hv) + Math.asin(x / hv) - (Math.PI / 2)
    x: Math.cos(alpha) * radius
    y: Math.sin(alpha) * radius

  left:
    roller: rollerPosition(hr1, hv1, x1)
    x: x1
  rright:
    roller: rollerPosition(hr2, hv2, x2)
    x: x2
  height: y

lineToStringLengths = (start, end, roller) ->
  a = distance(start, roller)
  b = distance(end, roller)
  c = distance(start, end)
  alpha = Math.acos (pow2(b) + pow2(c) - pow2(a)) / (2 * b * c)
  beta = Math.acos (pow2(a) + pow2(c) - pow2(b)) / (2 * a * c)
  height = triangleHeight(a,b,c)
  if alpha > PI/2 or beta > PI / 2
    [a, height, b]
  else
    [a, b]

distance = ({x: x1, y: y1}, {x: x2, y: y2}) ->
  Math.sqrt pow2(x1 - x2) + pow2(y1 - y2)

$left = document.getElementById("left")
$right = document.getElementById("right")
#$angles =
#  l: document.getElementById("leftAngle")
#  r: document.getElementById("rightAngle")


#updateState = ->
#  plotter.state.l = +$left.value
#  plotter.state.r = +$right.value
#  requestAnimationFrame ->
#    plotter.moveGandola()
#    plotter.render()

#$left.addEventListener 'keyup', updateState
#$right.addEventListener 'keyup', updateState
#$left.addEventListener 'change', updateState
#$right.addEventListener 'change', updateState

class Plotter
  stringLen: 730 * 2
  roller:
    d: 1154 - 18 * 2 # Distance between
    x: 18-0.5
    y: 18-0.5
    r: 24
    steps: 200 #per Revolution

  state:
    l: 730
    r: 625
    angles:
      l: 0
      r: 0
    x: null
    y: null
    rollers: null

  path: []

  relativePlan: []

  interactive: false

  constructor: (@ctx, properties=null) ->
    @prop = properties if properties
    @updatePosition()
    console.log @state

  clear: ->
    canvas.width = w

  renderRolleres: ->
    @ctx.lineWidth = 0.3
    @ctx.beginPath()
    drawForX = (x, side) =>
      @ctx.moveTo x + @roller.r, @roller.y
      @ctx.arc x, @roller.y, @roller.r, 0, Math.PI * 2
      @ctx.moveTo x + Math.cos(@state.angles[side]) * @roller.r, @roller.y + Math.sin(@state.angles[side]) * @roller.r
      @ctx.lineTo x + Math.cos(@state.angles[side] + PI) * @roller.r, @roller.y + Math.sin(@state.angles[side] + PI) * @roller.r

    drawForX @roller.x, 'l'
    drawForX @roller.d + @roller.x, 'r'

    @ctx.closePath()
    @ctx.stroke()

  renderCounterweights: ->
    @ctx.beginPath()
    @ctx.lineWidth = 1

    x = @roller.x - @roller.r
    @ctx.moveTo x, @roller.y
    @ctx.lineTo x, @roller.y + @stringLen - @state.l

    x = @roller.d + @roller.x + @roller.r
    @ctx.moveTo x, @roller.y
    @ctx.lineTo x, @roller.y + @stringLen - @state.r

    @ctx.closePath()
    @ctx.stroke()

  updatePosition: ->
    data = realHypStartPositions(@state.l, @state.r, @roller.d, @roller.r)
    @state.x = data.l.x
    @state.y = data.height
    @state.rollers = left: data.l.roller, right: data.r.roller
    @path.push [@state.x, @state.y]

  renderGandola: ->
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = 'black'

    @ctx.moveTo @roller.x + @state.rollers.left.x, @roller.y - @state.rollers.left.y
    @ctx.lineTo @roller.x + @state.x, @roller.y + @state.y

    @ctx.moveTo @roller.x + @roller.d - @state.rollers.right.x, @roller.y - @state.rollers.right.y
    @ctx.lineTo @roller.x + @state.x, @roller.y + @state.y

    @ctx.stroke()
    @ctx.closePath()

  renderPath: ->
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = '#ccc'
    for [x, y] in @path
      @ctx.lineTo @roller.x + x, @roller.y + y
    @ctx.stroke()
    @ctx.closePath()

  render: ->
    @clear()
    @renderRolleres()
    @renderCounterweights()
    @renderPath()
    @renderGandola() #with strings

  stepWheel: (side, direction=1) ->
    c = 2 * PI * @roller.r
    lenPerStep = c / @roller.steps
    anglePerStep = (2 * PI) / @roller.steps
    @state[side] += direction * lenPerStep
    direction *= -1 if side is 'r'
    @state.angles[side] += direction * anglePerStep

  start: ->
    instructions = @generateInstructions(_.clone(@state), @relativePlan)
#    document.getElementById("log").innerText = '\'' + instructions.join("','") + '\''
    @renederSimulation instructions
    return instructions

  renederSimulation: (instructions) ->
    renderInstruction = (i) =>
      instruction = instructions[i]
      if instruction.indexOf('l') isnt -1
        @stepWheel 'l', -1
      if instruction.indexOf('L') isnt -1
        @stepWheel 'l'
      if instruction.indexOf('r') isnt -1
        @stepWheel 'r', -1
      if instruction.indexOf('R') isnt -1
        @stepWheel 'r'

      @updatePosition()

      next = =>
        i++
        renderInstruction(i) if i < instructions.length

      if i % @speed is 0
        @render()
        requestAnimationFrame next
      else
        next()

    renderInstruction(0) if instructions.length

  generateInstructions: (state, relativePath) ->
    result = []
    @lineToInstructions(state, dx, dy, result) for [dx, dy] in relativePath
    return result

  lineToInstructions: (state, dx, dy, result=[]) ->
    # Result of call
    # 1. Returns list of frames with notation as 'lR' (left back, right forward) 'L' (left forward)
    # 2. Update state.x/y to predicted real position after performed moves

    lineEnd = x:state.x + dx, y:state.y + dy
    d = distance state, lineEnd
    return unless d
    samplesNumber = Math.ceil(d) * 2 # This constant should be tweaked

    samples =
      for i in [0..samplesNumber]
        portion = i / samplesNumber
        xx = state.x + (lineEnd.x - state.x) * portion
        yy = state.y + (lineEnd.y - state.y) * portion
        x: xx
        y: yy

    #TODO can be calculated once
    lengthPerTurn = 2 * PI * @roller.r / @roller.steps

    for sample in samples
      happy = false
      while not happy
        data = realHypStartPositions(state.l, state.r, @roller.d, @roller.r)
        state.x = data.l.x
        state.y = data.height

        calculateTurnsForSide = (origin, side)->
          targetD = distance origin, sample
          currentD = distance origin, state
#          console.log currentD - state[side]
#        newD = distance origin, sample
          # TODO What if currentLD - newLD >= lengthPerTurn * 2
          # Two or more steps should be performed between steps
          distanceDiff = targetD - currentD #state[side]
          needForStep = Math.abs(distanceDiff) >= lengthPerTurn
          happy = happy && Math.abs(distanceDiff) < lengthPerTurn * 2
          if needForStep
            bigger = distanceDiff > 0
            direction = bigger and 1 or -1
            state[side] += direction * lengthPerTurn
            bigger and side.toUpperCase() or side
          else
            ""

        happy = true
#        leftOrigin = {x:data[side].roller.x, y:data[side].roller.y}
#        rightOrigin = {x:@roller.d - data[side].roller.x, y:data[side].roller.y}
        instruction = calculateTurnsForSide({x:0, y:0}, 'l') + calculateTurnsForSide({x:@roller.d, y:0}, 'r')
        result.push instruction if instruction

    return result


[w, h] = [1170, 900]
canvas = document.getElementsByTagName('canvas').item(0)
canvas.width = w
canvas.height = h
ctx = canvas.getContext('2d')
plotter = new Plotter(ctx)
plotter.render()

#plotter.relativePlan = [
#  [0, -100]
#  [100, 0]
#  [0, 100]
#  [-100, 0]
#]

#Draw circles

x = plotter.state.x
y = plotter.state.y
r = 100
oldx = x + Math.cos(0) * r
oldy = y + Math.sin(0) * r
#plotter.relativePlan.push [10, -10]
sides = 10
times = 0
for t in [0..times]
  for i in [0..sides]
    angle = PI*2*(i/sides)
    newx = x + Math.cos(angle) * r
    newy = y + Math.sin(angle) * r
    dx = newx - oldx
    dy = newy - oldy
    plotter.relativePlan.push [dx, dy]
    oldx = newx
    oldy = newy

#x = plotter.state.x
#y = plotter.state.y
#times = 40
#angle = PI/4
#len = 10
#plotter.relativePlan.push [10, 10]
#for i in [1..times]
#  dx = Math.cos(angle) * len
#  dy = Math.sin(angle) * len
#  len += 10
#  angle += PI/2
#  plotter.relativePlan.push [dx, dy]

plotter.interactive = true
plotter.speed = 5
#plotter.start()

Driver = require("./node/driver").Driver
driver = new Driver()

document.getElementById("drawButton").addEventListener 'click', ->
  instructions = plotter.start()
  driver.on 'ready', ->
    @instructions = instructions
  driver.initialize()

#window.plotter = plotter
#plotter.goToState(l:100, r:500)

