freeport = require 'freeport'
childProcess = require 'child_process'
psTree = require 'ps-tree'

DEFAULT_CONFIG =
    dir: "/Users/adam/.wow"
    timeout: 20

class ServiceManager
    constructor: (config) ->
        @config = config or DEFAULT_CONFIG
        @services = {}
    getService: (name) ->
        if @services[name]?
            return @services[name]
        else
            service = new Service(this, name)
            @services[name] = service
            return service

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

        console.log "About to start up #{@name}"
        freeport (err, port) =>
            console.log "Starting up #{@name} on localhost:#{port}"
            @port = port
            processName = "#{@serviceManager.config.dir}/#{@name}"
            @process = childProcess.spawn processName, [@port]
            console.log "#{@name} is now running on PID #{@process.pid}"

            # Redirect stdout and stderr
            @process.stdout.on 'data', (data) =>
                console.log "#{@name} stdout: #{data}"
            @process.stderr.on 'data', (data) =>
                console.log "#{@name} stderr: #{data}"
            @process.on 'error', (error) =>
                console.log "#{@name} error: #{error}"

            # handle the server closing down
            @process.on 'close', (code, signal) =>
                console.log "Child process exited with code #{code}"
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
        console.log "Stopping #{@name}"
        if @process?
            psTree @process.pid, (err, children) =>
                for child in children
                    process.kill(child.PID)
                @process.kill()

exports.ServiceManager = ServiceManager
exports.Service = Service

