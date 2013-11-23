Vertical plotter software
=========================

I am making vertical plotter. It works on Arduino with thin layer for controlling motors.
Main logic is in client software. I have simulator and code that sends actual commands to Arduino.
Everything is written in WEB technologies (html, coffeescript, node, nodewebkit),
so one code drives simulator and actual motors.

(simulator)[/simulator] folder contains main application responsible for drawing simulation
and sending commands to the Arduino

(arduino)[/arduino] folder slightly modified firmata client code