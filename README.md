## Installation

It's my intention to make this a one-step process, but for now:

### Mac OS X

1. `npm install poxy`
2. `sudo poxy install`

### Linux & Windows

You're on your own, for now. You'll need to:

- Configure your computer to try to resolve queries ending with `.dev` with the DNS server running at `127.0.0.1:17698`. (On Linux, it looks like [this page](https://wiki.archlinux.org/index.php/Dnsmasq#DNS_Cache_Setup) might help.)
- Forward port 80 on your machine to port 17699
- Run `poxy`
