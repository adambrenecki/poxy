httpProxy = require 'http-proxy'
http = require 'http'
manager = require './manager'

myManager = new manager.ServiceManager()
myProxy = httpProxy.createServer (req, res, proxy) ->
    service = myManager.getService(req.headers.host)
    service.start ->
        proxy.proxyRequest req, res,
            host: 'localhost'
            port: service.port

myProxy.listen 10969
