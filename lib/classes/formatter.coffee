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

    if !@project or !@workspace
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
    @tempEditorPath = Temp.path({suffix: Path.extname(@textEditorPath)})
    Fs.copySync(@textEditorPath, @tempEditorPath) # Temp file.

    # Memory checkpoint and formatting.

    @checkpoint = @textEditor.createCheckpoint()
    @format() # Format the temp file; based on grammar.
    @textEditor.setText(Fs.readFileSync(@tempEditorPath).toString())

    # Memory restoration and text editor update.

    @textEditor.save() # Save updated file contents.
    @curscrop.restoreFromMemory() # Cursors & scrollTop.
    @textEditor.groupChangesSinceCheckpoint(@checkpoint)
    Temp.cleanupSync() # Just to be extra sure.

    # All done. Hide modal status.

    @modalStatus.destroy() # All done now.

  # --------------------------------------------------------------------------------------------------------------------
  # Format handler. Choose the right formatter; based on grammar.
  # --------------------------------------------------------------------------------------------------------------------

  format: -> # Based on language/grammar.

    switch @textEditorGrammarNameLower

      when 'php' # Primay focus.
        @formatPhp_viaPhpCsFixer()

      when 'html', 'xml'
        @formatHtml_viaJsBeautify()

      when 'json', 'javascript'
        @formatJs_viaJsBeautify()

      when 'css', 'scss', 'sass' # A user can choose prettyDiff w/ this undocumented option.
        if !@wsStyleGuidelines and String(atom.config.get('ws-toolbox.cssSassLessFormatter')).toLowerCase() is 'prettydiff'
          @formatCssSassLess_viaPrettyDiff() # This might be preferred by some.
        else @formatCssSass_viaSassConvert() # Best available option.

      when 'less' # Use PrettyDiff for LESS syntax.
        @formatCssSassLess_viaPrettyDiff() # @TODO improve.

      when 'coffeescript'
        @formatCoffeeScript_viaNothing()

  # --------------------------------------------------------------------------------------------------------------------
  # A few different types of code beautifiers/formatters.
  # --------------------------------------------------------------------------------------------------------------------

  formatPhp_viaPhpCsFixer: ->

    phpCsFixer = atom.config.get('ws-toolbox.phpCsFixerPath')
    if !phpCsFixer # Use default php-cs-fixer in $PATH?
      phpCsFixer = 'php-cs-fixer' # Default binary.

    homeConfigFile = process.env.HOME+'/.php_cs'
    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.php_cs')

    configFile = wsConfigFile # Default config. file.
    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      configFile = homeConfigFile # Personal config.

    phpCsFixer += " fix --config-file='"+configFile+"'"
    phpCsFixer += " '"+@tempEditorPath+"'"

    console.log('formatPhp_viaPhpCsFixer: `%s`', phpCsFixer)

    Command.runSync(phpCsFixer)

  # --------------------------------------------------------------------------------------------------------------------

  formatHtml_viaJsBeautify: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.html if typeof config.html is 'object'

    console.log('formatHtml_viaJsBeautify: %o', config)

    formattedText = Fs.readFileSync(@tempEditorPath).toString()
    formattedText = JsBeautify.html(formattedText, config)
    Fs.writeFileSync(@tempEditorPath, formattedText)

  # --------------------------------------------------------------------------------------------------------------------

  formatJs_viaJsBeautify: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME+'/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.js if typeof config.js is 'object'

    console.log('formatJs_viaJsBeautify: %o', config)

    formattedText = Fs.readFileSync(@tempEditorPath).toString()
    formattedText = JsBeautify.js(formattedText, config)
    Fs.writeFileSync(@tempEditorPath, formattedText)

  # --------------------------------------------------------------------------------------------------------------------

  formatCss_viaJsBeautify: ->

    JsBeautify = require('js-beautify')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.jsbeautifyrc')
    homeConfigFile = process.env.HOME + '/.jsbeautifyrc'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    console.log('formatCss_viaJsBeautify: %o', config)

    formattedText = Fs.readFileSync(@tempEditorPath).toString()
    formattedText = JsBeautify.css(formattedText, config)
    Fs.writeFileSync(@tempEditorPath, formattedText)

  # --------------------------------------------------------------------------------------------------------------------

  formatCssSass_viaSassConvert: ->

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

    Command.runSync(sassConvert)
    @_formatCssSassLess_viaCustomSpecials(config)

  # --------------------------------------------------------------------------------------------------------------------

  formatCssSassLess_viaPrettyDiff: ->

    PrettyDiff = require('prettydiff')

    wsConfigFile = Path.join(__dirname, '../dotfiles/ws/.prettydiff.json')
    homeConfigFile = process.env.HOME+'/.prettydiff.json'

    config = JSON.parse(Fs.readFileSync(wsConfigFile).toString())

    if !@wsStyleGuidelines and Fs.existsSync(homeConfigFile)
      $.extend(config, JSON.parse(Fs.readFileSync(homeConfigFile).toString()))
    config = config.css if typeof config.css is 'object'

    prettyDiffConfig = $.extend({}, config)
    prettyDiffConfig.source = Fs.readFileSync(@tempEditorPath).toString()
    prettyDiffConfig.lang = 'css' # Covers CSS/SASS/SCSS/LESS.
    prettyDiffConfig.mode = 'beautify' # Beautifying.

    console.log('formatCssSassLess_viaPrettyDiff: %o', config)

    formattedText = PrettyDiff.api(prettyDiffConfig)[0]
    Fs.writeFileSync(@tempEditorPath, formattedText)
    @_formatCssSassLess_viaCustomSpecials(config)

  # --------------------------------------------------------------------------------------------------------------------

  _formatCssSassLess_viaCustomSpecials: (config) ->

    sassAlign = atom.config.get('ws-toolbox.sassAlignPath')
    if !sassAlign # Use default sass-align in $PATH?
      sassAlign = 'sass-align' # Default binary.

    sassAlign += " --edit-in-place '"+@tempEditorPath+"'"

    if config.alignProperties is true
      console.log('&& `%s`', sassAlign)
      Command.runSync(sassAlign)

    formattedText = Fs.readFileSync(@tempEditorPath).toString()

    if config.quoteConvert is 'single'
      formattedText = formattedText.replace(/"/g, "'")

    else if config.quoteConvert is 'double'
      formattedText = formattedText.replace(/'/g, '"')

    if config.noEmptyLines # No empty lines?
      formattedText = formattedText.replace(/\n+/g, '\n')

    else if config.tightenAtRules is true # Tighten @ rules?
      formattedText = formattedText.replace(/^([ \t]*@.+?;)\n{2,}(?=[ \t]*@)/gm, '$1\n')

    Fs.writeFileSync(@tempEditorPath, formattedText)

  # --------------------------------------------------------------------------------------------------------------------

  formatCoffeeScript_viaNothing: -> # @TODO Find a decent formatter.

    console.log('formatCoffeeScript_viaNothing: `%s`', '')
