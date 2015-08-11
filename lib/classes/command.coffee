'use strict'

ChildProcess = require('child_process')

module.exports = # Static class members.

  run: (command, callback, options) ->

    if command # Callback is optional here.
      ChildProcess.exec command, options or {}, (error, stdout, stderr) ->
        callback error, stdout, stderr if typeof callback is 'function'

  runSync: (command, options) -> # Synchronous.

    if command # Synchronous; no callback here whatsoever.
      ChildProcess.execSync(command, options or {}).toString()
    else '' # Empty string in this case.
