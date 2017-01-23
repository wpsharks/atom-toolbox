'use strict'

Path = require('path')
Fs = require('fs-extra')
Temp = require('temp').track()
EscHtml = require('escape-html')
{$} = require('atom-space-pen-views')

Command = require('./command')
Curscrop = require('./curscrop')

module.exports = class Formatter

  constructor: (wsStyleGuidelines) ->

    # WebSharks style guidelines?

    @wsStyleGuidelines = wsStyleGuidelines
    if @wsStyleGuidelines is undefined # Use config value?
      @wsStyleGuidelines = atom.config.get('ws-toolbox.wsStyleGuidelines')

    # Fundamental properties.

    @project = atom.project
    @workspace = atom.workspace
    @pane = @workspace?.getActivePane()

    if !@project or !@workspace or !@pane
      return # Not possible.

    @textEditor = @workspace.getActiveTextEditor()
    @textEditorPath = @textEditor?.getPath()
    @textBuffer = @textEditor?.getBuffer()

    if !@textEditor or !@textEditorPath or !@textBuffer
      return # Not possible; unexpected error.

    @textEditorGrammarName = @textEditor.getGrammar().name
    @textEditorGrammarNameLower = @textEditorGrammarName?.toLowerCase()

    if !@textEditorGrammarName or !@textEditorGrammarNameLower
      return # Not possible; unknown grammar.

    # Instantiate cursors & scrollTop memory.

    @curscrop = new Curscrop(@textEditor, true)
    @curscrop.remember() # Remember cursors/scrollTop.

    # Constract and display modal status.

    @status = $('<div class="ws-toolbox -status"></div>')
    status = '<i class="-fa -fa-github -fa-2x"></i><i class="-fa -fa-cog -fa-2x -fa-spin"></i>'
    status += ' ... Formatting ' + EscHtml(@textEditorGrammarName)

    @status.html(status) # Fill the modal status div.
    @modalStatus = @workspace.addModalPanel(item: @status)

    # Save editor and create a temp file.

    @textEditor.save() # Save file contents.
    @tempEditorPath = Temp.mkdirSync()+'/'+Path.basename(@textEditorPath)
    Fs.copySync(@textEditorPath, @tempEditorPath) # Temp file.

    # Memory checkpoint and formatting.

    @checkpoint = @textEditor.createCheckpoint()

    @format( => # Format; based on grammar.

      formattedText = @getTempFileContents() # Formatted now.
      if formattedText # In case of unexpected failure.
        @textEditor.setText(formattedText)

      # Memory restoration and text editor update.

      @curscrop.restoreFromMemory() # Cursors & scrollTop.
      @textEditor.groupChangesSinceCheckpoint(@checkpoint)

      # Save the updated file contents.

      setTimeout( => # Slight delay for linter.
        @textEditor.save() # Triggers `onDidSave`.
      1000) # Slight delay before triggering save events.

      # All done. Hide modal status.

      @modalStatus.destroy() # All done now.
    )
  # --------------------------------------------------------------------------------------------------------------------
  # Misc. utilities.
  # --------------------------------------------------------------------------------------------------------------------

  getTempFileContents: -> # Temporary file.

    Fs.readFileSync(@tempEditorPath).toString()

  writeTempFileContents: (contents) ->

    Fs.writeFileSync(@tempEditorPath, contents)

  # --------------------------------------------------------------------------------------------------------------------
  # Format handler. Choose the right formatter; based on grammar.
  # --------------------------------------------------------------------------------------------------------------------

  format: (callback) -> # Based on language/grammar.

    switch @textEditorGrammarNameLower

      when 'php' # Primay focus.
        @formatPhp_viaPhpCsFixer(callback)

      when 'typescript'
        @formatTs_viaTypeScriptFormatter(callback)

      when 'html', 'xml'
        @formatHtml_viaJsBeautify(callback)

      when 'json', 'javascript'
        @formatJs_viaJsBeautify(callback)

      when 'css', 'scss', 'sass' # A user can choose prettyDiff w/ this undocumented option.
        if !@wsStyleGuidelines and String(atom.config.get('ws-toolbox.cssSassLessFormatter')).toLowerCase() is 'prettydiff'
          @formatCssSassLess_viaPrettyDiff(callback) # This might be preferred by some.
        else @formatCssSass_viaSassConvert(callback) # Best available option.

      when 'less' # Use PrettyDiff for LESS syntax.
        @formatCssSassLess_viaPrettyDiff(callback) # @TODO improve.

      when 'coffeescript'
        @formatCoffeeScript_viaNothing(callback)

      else callback()

  # --------------------------------------------------------------------------------------------------------------------
  # A few different types of code beautifiers/formatters.
  # --------------------------------------------------------------------------------------------------------------------

  formatPhp_viaPhpCsFixer: (callback) ->

    phpCsFixer = atom.config.get('ws-toolbox.phpCsFixerPath')
    if !phpCsFixer # Use default php-cs-fixer in $PATH?
      phpCsFixer = 'php-cs-fixer' # Default binary.

    homeConfigFile = process.env.HOME+'/.php_cs'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.php_cs')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    phpCsFixer += " fix --config='"+configFile+"'"
    phpCsFixer += " '"+@tempEditorPath+"'"

    console.log('formatPhp_viaPhpCsFixer: `%s`', phpCsFixer)

    Command.run(phpCsFixer, callback) # Final callback.

  # --------------------------------------------------------------------------------------------------------------------

  formatTs_viaTypeScriptFormatter: (callback) ->

    typeScriptFormatter = atom.config.get('ws-toolbox.TypeScriptFormatterPath')
    if !typeScriptFormatter # Use default php-cs-fixer in $PATH?
      typeScriptFormatter = 'tsfmt' # Default binary.

    homeConfigFile = process.env.HOME+'/.tsfmt.json'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.tsfmt.json')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    typeScriptFormatter += " --replace --baseDir='"+Path.dirname(configFile)+"'"
    typeScriptFormatter += " --no-tsconfig --no-tslint --no-editorconfig"
    typeScriptFormatter += " '"+@tempEditorPath+"'"

    console.log('formatTs_viaTypeScriptFormatter: `%s`', typeScriptFormatter)

    Command.run(typeScriptFormatter, callback) # Final callback.

  # --------------------------------------------------------------------------------------------------------------------

  formatHtml_viaJsBeautify: (callback) ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.html if typeof config.html is 'object'

    console.log('formatHtml_viaJsBeautify: %o', config)

    @writeTempFileContents(JsBeautify.html(@getTempFileContents(), config))
    callback() # Final callback on completion.

  # --------------------------------------------------------------------------------------------------------------------

  formatJs_viaJsBeautify: (callback) ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.js if typeof config.js is 'object'

    console.log('formatJs_viaJsBeautify: %o', config)

    @writeTempFileContents(JsBeautify.js(@getTempFileContents(), config))
    callback() # Final callback on completion.

  # --------------------------------------------------------------------------------------------------------------------

  formatCss_viaJsBeautify: (callback) ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME + '/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    console.log('formatCss_viaJsBeautify: %o', config)

    @writeTempFileContents(JsBeautify.css(@getTempFileContents(), config))
    callback() # Final callback on completion.

  # --------------------------------------------------------------------------------------------------------------------

  formatCssSass_viaSassConvert: (callback) ->

    sassConvert = atom.config.get('ws-toolbox.sassConvertPath')
    if !sassConvert # Use default sass-convert in $PATH?
      sassConvert = 'sass-convert' # Default binary.

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.sass-convert.json')
    homeConfigFile = process.env.HOME+'/.sass-convert.json'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))

    if config.dasherize is true
      sassConvert += ' --dasherize'

    if config.unixNewlines is true
      sassConvert += ' --unix-newlines'

    if config.indentSize # Integer or `t` for a tab.
      sassConvert += " --indent='"+config.indentSize+"'"

    if config.defaultEncoding # `UTF-8` is suggested here.
      sassConvert += " --default-encoding='"+config.defaultEncoding+"'"

    sassConvert += " --in-place '"+@tempEditorPath+"'"

    console.log('formatCssSassLess_viaSassConvert: `%s` %o', sassConvert, config)

    Command.run(sassConvert, => # Callback handler.
      @_formatCssSassLess_viaCustomSpecials(config, callback)
    )
  # --------------------------------------------------------------------------------------------------------------------

  formatCssSassLess_viaPrettyDiff: (callback) ->

    PrettyDiff = require('prettydiff')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.prettydiff.json')
    homeConfigFile = process.env.HOME+'/.prettydiff.json'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    pdConfig = $.extend({}, config)
    pdConfig.source = @getTempFileContents()
    pdConfig.lang = 'css' # Covers all abstractions.
    pdConfig.mode = 'beautify' # Beautifying.

    console.log('formatCssSassLess_viaPrettyDiff: %o', config)

    @writeTempFileContents(PrettyDiff.api(pdConfig)[0])
    @_formatCssSassLess_viaCustomSpecials(config, callback)

  # --------------------------------------------------------------------------------------------------------------------

  _formatCssSassLess_viaCustomSpecials: (config, callback) ->

    callbackWrapper = => # Callback wrapper.

      formattedText = @getTempFileContents()

      if config.quoteConvert is 'single'
        formattedText = formattedText.replace(/"/g, "'")

      else if config.quoteConvert is 'double'
        formattedText = formattedText.replace(/'/g, '"')

      if config.noEmptyLines # No empty lines?
        formattedText = formattedText.replace(/\n+/g, '\n')

      else if config.tightenAtRules is true # Tighten @ rules?
        formattedText = formattedText.replace(/^([ \t]*@.+?;)\n{2,}(?=[ \t]*@)/gm, '$1\n')

      @writeTempFileContents(formattedText)
      callback() # Final callback on completion.

    sassAlign = atom.config.get('ws-toolbox.sassAlignPath')
    if !sassAlign # Use default sass-align in $PATH?
      sassAlign = 'sass-align' # Default binary.

    sassAlign += " --edit-in-place '"+@tempEditorPath+"'"

    if config.alignProperties is true
      console.log('&& `%s`', sassAlign)
      Command.run(sassAlign, callbackWrapper)
    else callbackWrapper() # Run wrapper only.

  # --------------------------------------------------------------------------------------------------------------------

  formatCoffeeScript_viaNothing: (callback) -> # @TODO Find a decent formatter.

    console.log('formatCoffeeScript_viaNothing: `%s`', '')

    callback() # Final callback on completion.
