fs = require 'fs'
childProcess = require 'child_process'
async = require 'async'
require 'handlebars'

writeTemplateToFile = (templatePath, filePath, callback, context) ->
    console.log "# rendering #{templatePath} to #{filePath}"
    template = require templatePath
    content = template(context)
    fs.writeFile filePath, content, callback

checkCall = (cmd, args, callback) ->
    console.log "#{cmd} #{args.join(" ")}"
    proc = childProcess.spawn(cmd, args)
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
        plistLocationIpfw = "/Library/LaunchAgents/au.id.brenecki.adam.poxy.ipfw.plist"

        async.series [
            (cb) -> writeTemplateToFile "./templates/plist.hbs", plistLocation, cb,
                nodePath: process.execPath
                scriptPath: process.argv[1]
                arg: "run"
            (cb) -> checkCall "mkdir", ["-p", "/etc/resolver"], cb
            (cb) -> writeTemplateToFile "./templates/resolver.hbs", "/etc/resolver/dev", cb, {}
            (cb) -> writeTemplateToFile "./templates/plist-ipfw.hbs", plistLocationIpfw, cb, {}
            (cb) -> checkCall "launchctl", ["load", plistLocation], cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy"], cb
            (cb) -> checkCall "launchctl", ["load", plistLocationIpfw], cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy.ipfw"], cb
        ], (err) ->
            if err
                console.log "Oh no! #{err}"
            else
                console.log "Ready to go!"
    linux: -> console.log("Auto-install isn't supported yet on Linux.")
    win32: -> console.log("Auto-install isn't supported yet on Windows.")
    freebsd: -> console.log("Auto-install isn't supported yet on FreeBSD.")
    sunos: -> console.log("Auto-install isn't supported yet on SunOS.")
