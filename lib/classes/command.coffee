'use strict'

ChildProcess = require('child_process')

module.exports = # Static class members.

  run: (command, callback, options) ->

    if command # Callback is optional here.
      ChildProcess.exec command, options or {}, (error, stdout, stderr) ->
        callback error, stdout, stderr if typeof callback is 'function'

  runSync: (command, options) -> # Synchronous.

    response = '' # Initialize response.

    if command # Synchronous; no callback here whatsoever.
      try # In case of parse error or any other unexpectec behavior.
        response = ChildProcess.execSync(command, options or {}).toString()
      catch error # Catch, log, and then rethrow.
        console.log(error)
        throw error

    response # Return the response.
