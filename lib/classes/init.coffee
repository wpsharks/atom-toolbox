'use strict'

Command = require('./command')

module.exports = class Init

  constructor: -> # Constructor.

    @syncPath() # Sync on instantiation.

  syncPath: -> # Sync $PATH w/ current user's $PATH.

    shellExport = Command.runSync(process.env.SHELL + ' -lc export')

    for _line in shellExport.trim().split('\n')

      if _line.indexOf('=') is -1
        continue # Skip line.

      [_name, _value] = _line.split('=', 2)

      if /^(?:declare\s+\-x\s+)?PATH$/.test(_name)
        process.env.PATH = _value.replace(/^[\s"]+|[\s"]+$/g, '')
        break; # All done here.
