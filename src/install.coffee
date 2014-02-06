fs = require 'fs'
childProcess = require 'child_process'
async = require 'async'
config = require './config'
require 'handlebars'

writeTemplateToFile = (templatePath, filePath, rootOwned, callback, context) ->
    console.log "# rendering #{templatePath} to #{filePath}"
    template = require templatePath
    content = template(context)
    fs.writeFile filePath, content, callback
    if not rootOwned
        uid = parseInt process.env.SUDO_UID
        gid = parseInt process.env.SUDO_GID
        fs.chownSync filePath, uid, gid

checkCall = (cmd, args, rootOwned, callback) ->
    console.log "#{cmd} #{args.join(" ")}"
    options = {}
    if not rootOwned
        options.uid = parseInt process.env.SUDO_UID
        options.gid = parseInt process.env.SUDO_GID
    proc = childProcess.spawn(cmd, args, options)
    proc.stdout.on 'data', (data) ->
        console.log '' + data
    proc.stderr.on 'data', (data) ->
        console.log '' + data
    proc.on 'close', (code) ->
        if code == 0
            callback()
        else
            e = "Error: #{cmd} #{args} returned #{code}"
            console.log e
            callback(e)


module.exports =
    darwin: ->
        if not process.env.SUDO_UID?
            console.log "Please run this command using sudo."
            process.exit(1)

        plistLocation = process.env.HOME + "/Library/LaunchAgents/au.id.brenecki.adam.poxy.plist"
        plistLocationIpfw = "/Library/LaunchDaemons/au.id.brenecki.adam.poxy.ipfw.plist"

        async.series [
            (cb) -> writeTemplateToFile "./templates/plist.hbs", plistLocation, false, cb,
                nodePath: process.execPath
                scriptPath: process.argv[1]
                arg: "run"
            (cb) -> checkCall "mkdir", ["-p", "/etc/resolver"], true, cb
            (cb) -> checkCall "mkdir", ["-p", config.dir], false, cb
            (cb) -> checkCall "mkdir", ["-p", config.logdir], false, cb
            (cb) -> writeTemplateToFile "./templates/resolver.hbs", "/etc/resolver/dev", true, cb, {}
            (cb) -> writeTemplateToFile "./templates/plist-ipfw.hbs", plistLocationIpfw, true, cb, {}
            (cb) -> checkCall "launchctl", ["load", plistLocation], false, cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy"], false, cb
            (cb) -> checkCall "launchctl", ["load", plistLocationIpfw], true, cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy.ipfw"], true, cb
        ], (err) ->
            if err
                console.log "Oh no! #{err}"
            else
                console.log "Ready to go!"
    linux: -> console.log("Auto-install isn't supported yet on Linux.")
    win32: -> console.log("Auto-install isn't supported yet on Windows.")
    freebsd: -> console.log("Auto-install isn't supported yet on FreeBSD.")
    sunos: -> console.log("Auto-install isn't supported yet on SunOS.")
