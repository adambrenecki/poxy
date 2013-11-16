#!/usr/bin/env coffee

switch process.argv[2]
    when 'run'
        processmgr = require './processmgr'
        proxy = require './proxy'
        dns = require './dns'
        serviceManager = new processmgr.ServiceManager()
        m = new proxy(serviceManager)
        d = new dns()
        m.listen(17699)
        d.listen(17698)
    when 'install'
        install = require './install'
        install[process.platform]()
    when undefined
        console.log "What? Be more specific."
    else
        console.log "I don't know how to #{process.argv[2]}"
