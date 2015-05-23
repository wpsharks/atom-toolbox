'use strict'

ChildProcess = require('child_process')

module.exports = # Static class members.

  run: (command, callback, options) ->

    if command # Callback is optional here.
      ChildProcess.exec command, options, (error, stdout, stderr) ->
        callback error, stdout, stderr if typeof callback is 'function'

  runSync: (command, options) ->

    if command # No callback here whatsoever.
      ChildProcess.execSync(command, options).toString()
    else '' # Empty string in this case.
