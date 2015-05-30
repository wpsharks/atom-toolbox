'use strict'

Fs = require('fs')
Path = require('path')
{$} = require('atom-space-pen-views')
Command = require('./command')

module.exports = class Ctagger

  constructor: (wsStyleGuidelines) ->

    @wsStyleGuidelines = wsStyleGuidelines
    if @wsStyleGuidelines is undefined # Use config value?
      @wsStyleGuidelines = atom.config.get('ws-toolbox.wsStyleGuidelines')

    @project = atom.project
    @workspace = atom.workspace
    @textEditor = @workspace?.getActiveTextEditor()
    @textEditorPath = @textEditor?.getPath()

    if !@project or !@workspace or !@textEditor or !@textEditorPath
      return # Not possible in this case.

    @status = $('<div class="ws-toolbox-com-status"></div>')
    loading = '<i class="fa fa-tags fa-2x"></i>'
    loading += '<i class="fa fa-cog fa-2x fa-spin"></i>'
    loading += ' ... Generating CTags '
    @status.html(loading)

    ctags = atom.config.get('ws-toolbox.ctagsPath')
    if !ctags # Use default ctags in $PATH?
      ctags = 'ctags' # Default binary.

    homeConfigFile = process.env.HOME+'/.ctags.cnf'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.ctags.cnf')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    ctags += " --options='"+configFile+"'"

    console.log(ctags) # For debugging.

    @project.getPaths().forEach (projectPath) =>
      if @textEditorPath.indexOf(projectPath + '/') is 0
        @modalStatus = @workspace.addModalPanel(item: @status)
        Command.run(ctags, (=> @modalStatus.destroy()), cwd: projectPath)
