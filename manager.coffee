httpProxy = require 'http-proxy'
http = require 'http'
service = require './service'

DEFAULT_CONFIG =
    dir: "/Users/adam/.wow"
    timeout: 20000

class ServiceManager
    constructor: (config) ->
        @config = config or DEFAULT_CONFIG
        @services = {}
    getService: (name) =>
        if @services[name]?
            return @services[name]
        else
            service = new service.Service(this, name)
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

exports.ServiceManager = ServiceManager
