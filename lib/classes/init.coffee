'use strict'

Command = require('./command')

module.exports = class Init

  constructor: ->

    @syncPath()

  syncPath: ->

    shellExport = Command.runSync(process.env.SHELL + ' -lc export')

    for _line in shellExport.trim().split('\n')

      if _line.indexOf('=') is -1
        continue # Not applicable.

      [_name, _value] = _line.split('=', 2)

      if /^declare\s+\-x\s+PATH$/.test(_name)
        process.env.PATH = _value.replace(/^[\s"]+|[\s"]+$/g, '')
        break; # All done here.
