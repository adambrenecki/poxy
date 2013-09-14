freeport = require 'freeport'
childProcess = require 'child_process'
psTree = require 'ps-tree'
httpProxy = require 'http-proxy'
http = require 'http'
path = require 'path'

HOME = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

DEFAULT_CONFIG =
    dir: path.join HOME, ".poxy"
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

    start: (readyCallback) =>
        if @stopTimeout?
            clearTimeout @stopTimeout
        @stopTimeout = setTimeout @stop, @serviceManager.config.timeout

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

module.exports =
    ServiceManager: ServiceManager
    Service: Service