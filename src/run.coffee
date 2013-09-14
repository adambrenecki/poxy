#!/usr/bin/env coffee

switch process.argv[2]
    when 'run'
        manager = require './manager'
        m = new manager.ServiceManager()
        m.listen(10969)
    when 'install'
        install = require './install'
        install.macosx()
    when undefined
        console.log "What? Be more specific."
    else
        console.log "I don't know how to #{process.argv[2]}"
