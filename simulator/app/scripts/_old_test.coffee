Driver = require("./node/driver").Driver
driver = new Driver()
driver.on 'ready', -> console.log 'connected'
driver.on 'start', -> console.log 'started'
driver.doInstructions([1, -1] for i in [0..100])
driver.initialize()

