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
    macosx: ->
        plistLocation = process.env.HOME + "/Library/LaunchAgents/au.id.brenecki.adam.poxy.plist"

        async.parallel [
            (cb) -> writeTemplateToFile "./templates/plist.hbs", plistLocation, cb,
                nodePath: process.execPath
                scriptPath: process.argv[1]
                arg: "run"
            (cb) -> checkCall "launchctl", ["load", plistLocation], cb
            (cb) -> checkCall "launchctl", ["start", "au.id.brenecki.adam.poxy"], cb
        ]
