#!/usr/bin/env coffee

switch process.argv[2]
    when 'run'
        proxy = require './proxy'
        dns = require './dns'
        m = new proxy.ServiceManager()
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
