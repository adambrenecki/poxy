# This is a modified version of the DNS server built in to 37signals' Pow.
# Copyright (c) 2013 Sam Stephenson, 37signals
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# This DNS server is designed to respond to DNS `A` queries with
# `127.0.0.1` for all requests it recieves.

dnsserver = require "dnsserver"

NS_T_A = 1
NS_C_IN = 1
NS_RCODE_NXDOMAIN = 3

module.exports = class DnsServer extends dnsserver.Server
  # Create a `DnsServer` with the given `Configuration` instance. The
  # server installs a single event handler for responding to DNS
  # queries.
  constructor: ->
    super
    @on "request", @handleRequest

  # The `listen` method is just a wrapper around `bind` that makes
  # `DnsServer` quack like a `HttpServer` (for initialization, at
  # least).
  listen: (port, callback) ->
    @bind port
    callback?()

  # Each incoming DNS request ends up here. If it's an `A` query
  # and the domain name matches the top-level domain specified in our
  # configuration, we respond with `127.0.0.1`. Otherwise, we respond
  # with `NXDOMAIN`.
  handleRequest: (req, res) =>
    q = req.question ? {}

    if q.type is NS_T_A and q.class is NS_C_IN
      res.addRR q.name, NS_T_A, NS_C_IN, 600, "127.0.0.1"
    else
      res.header.rcode = NS_RCODE_NXDOMAIN

    res.send()
