freeport = require 'freeport'
childProcess = require 'child_process'
psTree = require 'ps-tree'
httpProxy = require 'http-proxy'
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
    getProxy: =>
        myProxy = httpProxy.createServer (req, res, proxy) =>
            service = @getService(req.headers.host)
            service.start ->
                proxy.proxyRequest req, res,
                    host: 'localhost'
                    port: service.port
        return myProxy
    listen: (port) =>
        @getProxy().listen(port)

class Service
    constructor: (serviceManager, name) ->
        @serviceManager = serviceManager
        @name = name
        @port = null
        @process = null
        @stopTimeout = null
        @state = @states.stopped
        @readyCallbacks = []

    states:
        stopped: 0
        starting: 1
        running: 2

    start: (readyCallback) =>
        if @stopTimeout?
            clearTimeout @stopTimeout
        @stopTimeout = setTimeout @stop, @serviceManager.config.timeout

        if @state == @states.running
            readyCallback()
            return
        if @state == @states.starting
            @readyCallbacks.push readyCallback
            return

        @state = @states.starting


        freeport (err, port) =>
            @port = port
            processName = "#{@serviceManager.config.dir}/#{@name}"
            @process = childProcess.spawn processName, [@port]
            console.log "#{@name}: running on port #{port}, PID #{@process.pid}"

            # Redirect stdout and stderr to a file
            out = fs.createWriteStream path.join(@serviceManager.config.logdir, @name), {flags: 'a', encoding: 'utf8'}
            @process.stdout.on 'data', (data) =>
                console.log "#{@name} stdout: #{data}"
                out.write data
            @process.stderr.on 'data', (data) =>
                console.log "#{@name} stderr: #{data}"
                out.write data
            @process.on 'error', (error) =>
                console.log "#{@name} error: #{error}"
                out.write "[poxy] encountered error: #{error}\n"

            # handle the server closing down
            @process.on 'close', (code, signal) =>
                console.log "#{@name}: stopped, code #{code}, signal #{signal}"
                @port = null
                @process = null
                @state = @states.stopped

            # wait until it starts responding to TCP connections before connecting
            tester = =>
                if @process # don't keep trying to connect if the process crashes
                    testClient = net.createConnection @port, () ->
                        testClient.end()
                    testClient.on 'end', () =>
                        # ready to run
                        @state = @states.running
                        readyCallback()
                        for c in @readyCallbacks
                            c()
                        @readyCallbacks = []
                    testClient.on 'error', (e) ->
                        if e.code in ['ECONNREFUSED']
                            setTimeout tester, 1000
            tester()


    stop: =>
        # Kills the server process, and all its children (such as those spawned
        # by e.g. Django's autoreloader or a shell script w/o exec).
        console.log "#{@name}: stop requested"
        if @process?
            @process.kill('SIGSTOP')
            psTree @process.pid, (err, children) =>
                for child in children
                    process.kill(child.PID, 'SIGSTOP')
                for child in children
                    process.kill(child.PID)
                @process.kill()

module.exports =
    ServiceManager: ServiceManager
    Service: Service
