httpProxy = require 'http-proxy'

module.exports = class Proxy
    constructor: (manager) ->
        @_proxy = httpProxy.createServer (req, res, proxy) =>
            service = manager.getService(req.headers.host)
            service.start ->
                proxy.proxyRequest req, res,
                    host: 'localhost'
                    port: service.port
    listen: (port) =>
        @_proxy.listen(port)

