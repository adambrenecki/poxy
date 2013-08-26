freeport = require 'freeport'
childProcess = require 'child_process'
psTree = require 'ps-tree'

class Service
    constructor: (serviceManager, name) ->
        @serviceManager = serviceManager
        @name = name
        @port = null
        @process = null

    start: (readyCallback) =>
        if @process?
            readyCallback()
            return

        freeport (err, port) =>
            @port = port
            processName = "#{@serviceManager.config.dir}/#{@name}"
            @process = childProcess.spawn processName, [@port]
            console.log "#{@name}: running on port #{port}, PID #{@process.pid}"

            # Redirect stdout and stderr
            @process.stdout.on 'data', (data) =>
                console.log "#{@name} stdout: #{data}"
            @process.stderr.on 'data', (data) =>
                console.log "#{@name} stderr: #{data}"
            @process.on 'error', (error) =>
                console.log "#{@name} error: #{error}"

            # handle the server closing down
            @process.on 'close', (code, signal) =>
                console.log "#{@name}: stopped, code #{code}, signal #{signal}"
                @port = null
                @process = null

            # set a timeout to shut the server down
            setTimeout @stop, 5000

            # TODO: Wait until the server is ready to accept connections
            # before running the callback

            readyCallback()

    stop: =>
        # Kills the server process, and all its children (such as those spawned
        # by e.g. Django's autoreloader or a shell script w/o exec).
        console.log "#{@name}: stop requested"
        if @process?
            psTree @process.pid, (err, children) =>
                for child in children
                    process.kill(child.PID)
                @process.kill()

exports.Service = Service

