#!/usr/bin/env coffee

manager = require './manager'

m = new manager.ServiceManager()
m.listen(10969)
