'use strict'

Fs = require('fs')
Path = require('path')
EscHtml = require('escape-html')
{$} = require('atom-space-pen-views')
Command = require('./command')

module.exports = class Formatter

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

    @textEditorGrammarName = @textEditor?.getGrammar().name
    @textEditorGrammarNameLower = @textEditorGrammarName?.toLowerCase()

    @textEditor.save() # Save text editor.

    @status = $('<div class="ws-toolbox-com-status"></div>')
    loading = '<i class="fa fa-github fa-2x"></i>'
    loading += '<i class="fa fa-cog fa-2x fa-spin"></i>'
    loading += ' ... Formatting ' + EscHtml(@textEditorGrammarName)
    @status.html(loading)

    @modalStatus = @workspace.addModalPanel(item: @status)

    switch @textEditorGrammarNameLower

      when 'php'
        @formatPhp =>
          @textEditor.getBuffer().reload()
          @modalStatus.destroy()

      when 'html', 'xml'
        @textEditor.setText (@formatHtml())
        @textEditor.save()
        @modalStatus.destroy()

      when 'css'
        @textEditor.setText (@formatCss())
        @textEditor.save()
        @modalStatus.destroy()

      when 'json', 'javascript'
        @textEditor.setText (@formatJavaScript())
        @textEditor.save()
        @modalStatus.destroy()

      when 'scss', 'sass', 'less'
        @textEditor.setText (@formatSassLess())
        @textEditor.save()
        @modalStatus.destroy()

      when 'coffeescript'
        @textEditor.setText (@formatCoffeeScript())
        @textEditor.save()
        @modalStatus.destroy()

      else @modalStatus.destroy()

  formatPhp: (callback) ->

    phpCsFixer = atom.config.get('ws-toolbox.phpCsFixerPath')
    if !phpCsFixer # Use default php-cs-fixer in $PATH?
      phpCsFixer = 'php-cs-fixer' # Default binary.

    homeConfigFile = process.env.HOME+'/.php_cs'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.php_cs')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    phpCsFixer += " fix --config-file='"+configFile+"'"
    phpCsFixer += " '"+@textEditorPath+"'"

    console.log(phpCsFixer) # For debugging.

    Command.run(phpCsFixer, callback)

  formatHtml: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.html if typeof config.html is 'object'

    JsBeautify.html(@textEditor.getText(), config)

  formatCss: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME + '/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    JsBeautify.css(@textEditor.getText(), config)

  formatJavaScript: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.js if typeof config.js is 'object'

    JsBeautify.js(@textEditor.getText(), config)

  formatSassLess: ->

    PrettyDiff = require('prettydiff')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.prettydiff.json')
    homeConfigFile = process.env.HOME+'/.prettydiff.json'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    config.mode = 'beautify' # Force.
    config.lang = 'css' # Force CSS lang.
    config.source = @textEditor.getText()

    result = PrettyDiff.api(config)[0]

    if typeof config.quoteConvert is 'string'
      if config.quoteConvert is 'single'
        result = result.replace /"/g, "'"
      else if config.quoteConvert is 'double'
        result = result.replace /'/g, '"'

    return result # Return the result.

  formatCoffeeScript: ->

    @textEditor.getText()
