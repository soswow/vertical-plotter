domById = (id) -> document.getElementById id

if typeof exports isnt 'undefined'
  Driver = exports("./driver").Driver
  driver = new Driver()

canvas = document.getElementsByTagName('canvas').item(0)
canvas.width = 620
canvas.height = 400


settings =
  distance: +domById("pulleysDistance").value
  pulleyRadius: +domById("pulleyRadius").value
  stepsPerRev: +domById("stepsPerRev").value
  virtualSpeed: +domById("virtualSpeed").value

state =
  left: +domById("leftLength").value
  right: +domById("rightLength").value

renderer = new scope.PlotterRenderer(canvas)
plotter = new scope.Plotter(renderer, driver, settings, state)

domById("drawButton").addEventListener 'click', ->
  x = plotter.state.x
  y = plotter.state.y
  r = 100
  oldx = x + Math.cos(0) * r
  oldy = y + Math.sin(0) * r
  #plotter.relativePlan.push [10, -10]
  sides = 10

  relativePath =
    for i in [0..sides]
      angle = Math.PI * 2 * (i/sides)
      newx = x + Math.cos(angle) * r
      newy = y + Math.sin(angle) * r
      dx = newx - oldx
      dy = newy - oldy
      oldx = newx
      oldy = newy
      [dx, dy]

  plotter.draw relativePath, true, false

domIdToSetting =
  virtualSpeed: 'virtualSpeed'
  pulleysDistance: 'distance'
  pulleyRadius: 'pulleyRadius'
  stepsPerRev: 'stepsPerRev'

for domId, name of domIdToSetting
  do (name) ->
    domById(domId).addEventListener 'change', ->
      plotter.updateSettings name, +@value

for side in ['left', 'right']
  do (side) ->
    domById(side + 'Length').addEventListener 'change', ->
      plotter.updateState side, +@value