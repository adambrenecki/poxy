## Installation

It's my intention to make this a one-step process, but for now:

### Mac OS X

1. `npm install poxy`
2. `brew install dnsmasq`
3. `echo "address=/dev/127.0.0.1\nlisten-address=127.0.0.1" > /etc/local/dnsmasq.conf`
4. `sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist`
5. `echo "nameserver 127.0.0.1\nport 53" | sudo tee /etc/resolver/dev`
6. `sudo ipfw add 100 fwd 127.0.0.1,10969 tcp from any to any 80 in`
7. `poxy`

Note: You'll need to do the last two steps every time you start your computer (for now, at least).

### Linux & Windows

You're on your own, for now. You'll need to:

- Run a DNS server on localhost that responds to all requests ending in `.dev` with `127.0.0.1`
- Configure your computer to talk to that DNS server first, before the others. (On Linux, it looks like [this page](https://wiki.archlinux.org/index.php/Dnsmasq#DNS_Cache_Setup) might help.)
- Forward port 80 on your machine to port 10969
- Run `poxy`
