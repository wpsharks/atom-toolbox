'use strict'

Init = require('./classes/init')
Ctagger = require('./classes/ctagger')
Formatter = require('./classes/formatter')
{CompositeDisposable} = require('atom')

module.exports = # Static class members.

  config:

    ctagsPath:
      title: 'cTags Path'
      description: '`$ brew tap websharks-formulas && brew install websharks-ctags`.' +
                    ' Then enter `ctags` here. Or `/usr/local/bin/ctags`.'
      type: 'string'
      default: ''

    phpCsFixerPath:
      title: 'PHP CS Fixer Path'
      description: '`$ brew install php-cs-fixer && php-cs-fixer self-update`.' +
                    ' Then enter `php-cs-fixer` here. Or `/usr/local/bin/php-cs-fixer`.'
      type: 'string'
      default: ''

    sassConvertPath:
      title: 'Sass-Convert Path'
      description: '`$ brew install ruby && gem install sass`.' +
                    ' Then enter `sass-convert` here. Or `/usr/local/bin/sass-convert`.'
      type: 'string'
      default: ''

    sassAlignPath:
      title: 'Sass-Align Path'
      description: '`$ brew install ruby && gem install sass-align`.' +
                    ' Then enter `sass-align` here. Or `/usr/local/bin/sass-align`.'
      type: 'string'
      default: ''

    wsStyleGuidelines:
      title: 'Use WebSharks Style Guidelines?'
      description: 'If checked, toolbox sub-routines will not look for config files in your home directory.' +
                    ' In other words, the default WebSharks style guidelines are enforced when this is checked.' +
                    ' Note: If you choose to uncheck this and use your own personal style guidelines, you can' +
                    ' still enforce WebSharks style guidelines on some projects. This is accomplished by using' +
                    ' special alt-key commands that are provided by this package. For instance, the shortcut' +
                    ' `ctrl-alt-cmd-f` calls `ws-toolbox:format-ws`; i.e., you can force WS style guidelines.'
      type: 'boolean'
      default: true

  activate: (state) ->

    new Init # Initialize.

    @commands = atom.commands
    @subscriptions = new CompositeDisposable

    @subscriptions.add @commands.add 'atom-text-editor', 'ws-toolbox:ctags': => @comCtags()
    @subscriptions.add @commands.add 'atom-text-editor', 'ws-toolbox:ctags-ws': => @comCtags(true)

    @subscriptions.add @commands.add 'atom-text-editor', 'ws-toolbox:format': => @comFormat()
    @subscriptions.add @commands.add 'atom-text-editor', 'ws-toolbox:format-ws': => @comFormat(true)

  comCtags: (wsStyleGuidelines) -> # CTags generator; against current project directory.

    new Ctagger(wsStyleGuidelines)

  comFormat: (wsStyleGuidelines) -> # Code formatter/beautifier.

    new Formatter(wsStyleGuidelines)

  deactivate: -> # Teardown.

    @subscriptions.dispose()
