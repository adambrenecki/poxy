fs = require 'fs'
childProcess = require 'child_process'
async = require 'async'
require 'handlebars'

writeTemplateToFile = (templatePath, filePath, callback, context) ->
    template = require templatePath
    content = template(context)
    fs.writeFile filePath, content, callback

checkCall = (cmd, args, callback) ->
    proc = childProcess.spawn(cmd, args)
    proc.on 'close', (code) ->
        if code == 0
            callback()
        else
            callback("Error: #{cmd} #{args} returned #{code}")


module.exports =
    darwin: ->
        if not process.env.SUDO_UID?
            console.log "Please run this command using sudo."
            process.exit(1)

        plistLocation = process.env.HOME + "/Library/LaunchAgents/au.id.brenecki.adam.poxy.plist"
        plistLocationIpfw = "/Library/LaunchAgents/au.id.brenecki.adam.poxy.ipfw.plist"

        async.parallel [
            (cb) -> writeTemplateToFile "./templates/plist.hbs", plistLocation, cb,
                nodePath: process.execPath
                scriptPath: process.argv[1]
                arg: "run"
            (cb) -> writeTemplateToFile "./templates/resolver.hbs", "/etc/resolver/dev", cb, {}
            (cb) -> writeTemplateToFile "./templates/plist-ipfw.hbs", plistLocationIpfw, cb, {}
            (cb) -> checkCall "launchctl", ["load", plistLocation], cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy"], cb
            (cb) -> checkCall "launchctl", ["load", plistLocationIpfw], cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy.ipfw"], cb
        ]
    linux: -> console.log("Auto-install isn't supported yet on this OS.")
    win32: -> console.log("Auto-install isn't supported yet on this OS.")
    freebsd: -> console.log("Auto-install isn't supported yet on this OS.")
    sunos: -> console.log("Auto-install isn't supported yet on this OS.")
