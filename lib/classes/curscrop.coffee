'use strict'

module.exports = class Curscrop

  constructor: (textEditor, alsoRememberScrollTop) ->

    @textEditor = textEditor # In a workspace.
    @textEditorElement = atom.views.getView(@textEditor)
    @alsoRememberScrollTop = alsoRememberScrollTop

    @scrollTop = 0 # Initialize properties.
    @bufferPositions = [] # Initialize.

  remember: -> # Remember cursors.

    @scrollTop = 0 # Initialize/reset memory.
    @bufferPositions = [] # Initialize.

    for _cursor in @textEditor.getCursors()
      bufferPosition = _cursor.getBufferPosition()
      @bufferPositions.push([bufferPosition.row, bufferPosition.column])

    if @alsoRememberScrollTop # Remember?
      @scrollTop = @textEditorElement.getScrollTop()

  restoreFromMemory: -> # Restore from memory.

    for _bufferPosition, _index in @bufferPositions

      if _index is 0 # A single cursor position first!
        @textEditor.setCursorBufferPosition(_bufferPosition)
      else @textEditor.addCursorAtBufferPosition(_bufferPosition)

    if @alsoRememberScrollTop # Restore scroll top?
      setTimeout( => # Restore scrollbar.
        @textEditorElement.setScrollTop(@scrollTop)
      5) # Slight delay.
