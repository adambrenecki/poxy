freeport = require 'freeport'
childProcess = require 'child_process'
psTree = require 'ps-tree'
http = require 'http'
path = require 'path'
fs = require 'fs'
net = require 'net'

HOME = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

DEFAULT_CONFIG =
    dir: path.join HOME, ".poxy"
    logdir: path.join HOME, ".poxylogs"
    timeout: 3600000

class ServiceManager
    constructor: (config) ->
        @config = config or DEFAULT_CONFIG
        @services = {}
    getService: (name) =>
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
        @stopTimeout = null
        @readyCallbacks = []

    start: (readyCallback) =>
        if @stopTimeout?
            clearTimeout @stopTimeout
        @stopTimeout = setTimeout @stop, @serviceManager.config.timeout

        if @state() == 'running'
            readyCallback()
            return

        @readyCallbacks.push readyCallback
        if @state() == 'starting'
            return

        @state 'starting'
        freeport (err, port) =>
            @port = port
            processName = "#{@serviceManager.config.dir}/#{@name}"
            @process = childProcess.spawn processName, [@port]
            @log 'starter', "running on #{port}, PID #{@process.pid}"

            # Redirect stdout and stderr to a file
            out = fs.createWriteStream path.join(@serviceManager.config.logdir, @name), {flags: 'a', encoding: 'utf8'}
            @process.stdout.on 'data', (data) =>
                @log 'stdout', data
                out.write data
            @process.stderr.on 'data', (data) =>
                @log 'stderr', data
                out.write data
            @process.on 'error', (error) =>
                @log 'error', error
                out.write "[poxy] encountered error: #{error}\n"

            # handle the server closing down
            @process.on 'close', (code, signal) =>
                @log 'close', "code #{code}, signal #{signal}"
                @port = null
                @process = null
                @state 'stopped'

            # wait until it starts responding to TCP connections before connecting
            tester = =>
                if @process # don't keep trying to connect if the process crashes
                    testClient = net.createConnection @port, () ->
                        testClient.end()
                    testClient.on 'end', () =>
                        # ready to run
                        @state 'running'
                    testClient.on 'error', (e) ->
                        if e.code in ['ECONNREFUSED']
                            setTimeout tester, 1000
            tester()


    stop: =>
        # Kills the server process, and all its children (such as those spawned
        # by e.g. Django's autoreloader or a shell script w/o exec).
        @log 'executioner', 'kill requested'
        if @process?
            psTree @process.pid, (err, children) =>
                for child in children
                    process.kill(child.PID)
                @process.kill()

    state: (newState) =>
        # Keeps track of state and runs certain state-transition tasks
        oldState = @__state
        if not newState?
            return oldState
        if newState not in ['stopped', 'starting', 'running']
            throw new Error("Invalid state #{newState}")
        @log 'state', "#{oldState} -> #{newState}"
        @__state = newState

        # state-transition tasks
        if oldState == 'starting'
            if newState == 'running'
                for callback in @readyCallbacks
                    callback()
            @readyCallbacks = []

    log: (feature, msg) ->
        console.log "[#{@name} #{feature}] #{msg}"

module.exports =
    ServiceManager: ServiceManager
    Service: Service
