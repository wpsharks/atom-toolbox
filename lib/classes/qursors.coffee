'use strict'

Path = require('path')
Fs = require('fs-extra')
{CompositeDisposable} = require('atom')
{$} = require('atom-space-pen-views')

module.exports = class Qursors

  constructor: () ->

    @project = atom.project
    @workspace = atom.workspace
    @pane = @workspace?.getActivePane()

    if !@project or !@workspace or !@pane
      return # Not possible.

    @textEditor = @workspace?.getActiveTextEditor()
    @textEditorPath = @textEditor?.getPath()

    if !@textEditor or !@textEditorPath
      return # Not possible.

    @commands = atom.commands
    @subscriptions = new CompositeDisposable

    @history        = null # Initialize.
    @historyFile = process.env.HOME+'/.atom/.qursors'

    if Fs.existsSync(@historyFile)
      @history = Fs.readFileSync(@historyFile).toString()
    @history = if @history then @history.split(/\n+/) else []
    @historyPoint = @history.length

    @$inputDiv = $('<div class="ws-toolbox -qursors native-key-bindings"></div>')
    @$inputDiv.html('<input type="text" />') # Keepin' it simple.

    @modalPanel = @workspace.addModalPanel(item: @$inputDiv)
    @$input = @$inputDiv.find('> input')

    @$input.on 'keydown', (event) =>
      @onInputKeypress(event)

    @$input.focus() # Move cursor.

    @subscriptions.add @commands.add 'atom-text-editor',
      'core:close'   : => @close()
      'core:cancel'  : => @close()

  createCursors: () ->

    pattern = @$input.val()
    totalCursors = 0 # Initialize.

    if (regex = /^\/(.*?)\/([gimy]*)$/.exec(pattern))
      regex = new RegExp(regex[1], regex[2])
    else regex = new RegExp(@quoteRegex(pattern), 'ig')

    # Remove any existing cursors.
    @textEditor.setCursorScreenPosition([0,0], autoscroll: false)

    @textEditor.scan regex, (m) =>
      if totalCursors is 0 # The first cursor.
        @textEditor.setCursorScreenPosition(m.range.start, autoscroll: true)
      else @textEditor.addCursorAtScreenPosition(m.range.start)
      ++totalCursors # Increment cursor counter.

    @updateHistory(pattern)

  inputHistoryScroll: (dir) ->

    if dir is 'up' # ↑

      if --@historyPoint < 0
        @historyPoint = 0

    else if dir is 'down' # ↓

      if ++@historyPoint > @history.length
        @historyPoint = @history.length

    if typeof @history[@historyPoint] is 'string'
      @$input.val(@history[@historyPoint])
    else @$input.val('') # Empty.

  updateHistory: (pattern) ->

    if pattern
      @history.push(pattern)

    @history = @history.filter (value, index) =>
      return index is @history.indexOf(value)

    @history = @history.slice(-100)
    @historyPoint = @history.length

    Fs.writeFileSync(@historyFile, @history.join('\n'))

  quoteRegex: (str) -> # Quotes regex meta chars.

    return str.replace(/([.\\+*?[\^\]$(){}=!<>|:\-])/g, '\\$1')

  onInputKeypress: (event) ->

    if event.which is 38 # ↑
      @inputHistoryScroll('up')
      return

    if event.which is 40 # ↓
      @inputHistoryScroll('down')
      return

    if event.which is 27 # Escape
      @close()
      return

    if event.which is 13 # Enter
      @createCursors()
      @close()
      return

  close: () ->

    @modalPanel?.destroy()
    @subscriptions?.dispose()
    @pane?.activate()
