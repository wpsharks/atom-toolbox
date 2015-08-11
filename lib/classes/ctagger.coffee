'use strict'

Path = require('path')
Fs = require('fs-extra')
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

    if !@project or !@workspace
      return # Not possible.

    if !@textEditor or !@textEditorPath
      return # Not possible.

    @status = $('<div class="ws-toolbox -status"></div>')
    loading = '<i class="-fa -fa-tags -fa-2x"></i><i class="-fa -fa-cog -fa-2x -fa-spin"></i>'
    loading += ' ... Generating CTags ' # Nothing more to say here.
    @status.html(loading) # Display status.

    ctags = atom.config.get('ws-toolbox.ctagsPath')
    if !ctags # Use default ctags in $PATH?
      ctags = 'ctags' # Default binary.

    homeConfigFile = process.env.HOME+'/.ctags.cnf'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.ctags.cnf')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    ctags += " --options='"+configFile+"'"

    console.log('Generating CTags: `%s`', ctags) # For debugging.

    @project.getPaths().forEach (projectPath) =>
      if @textEditorPath.indexOf(projectPath + '/') is 0
        @modalStatus = @workspace.addModalPanel(item: @status)
        Command.run(ctags, (=> @modalStatus.destroy()), cwd: projectPath)
