{CompositeDisposable} = require 'atom'
Tween = require 'gsap'
_ = require 'underscore'

module.exports = animatedPageScroll =
  config:
    scrollDuration:
      type: 'number'
      default: 0.3
      minimum: 0
      maximum: 5
      description: 'scroll duration in seconds.'
      order: 1
    rowModifier:
      type: 'number'
      default: 0
      minimum: 0
      maximum: 10
      description: 'row modifier.'
      order: 2
    scrollRows:
      type: 'integer'
      default: 3
      minimum: 1
      maximum: 50
      description: 'Row threshold for smoothing.'
      order: 3

  # https://raw.githubusercontent.com/halohalospecial/atom-animated-page-scroll/master/lib/animated-page-scroll.coffee
  # https://raw.githubusercontent.com/farcaller/typewriter-scroll/master/lib/typewriter-editor.coffee

  activate: (state) ->
    @anims = {}
    @subscriptions = new CompositeDisposable
    # throttled = _.throttle(@scrollPage, 25, 1)
    # document.onkeypress = @scrollPage
    # @cursorChangePosSubscription = atom.workspace.getActiveTextEditor().onDidChangeCursorPosition throttled
    # throttled = _.debounce(console.log('hello world'), 600)
    # document.onkeypress = @debounce @scrollPage, 300
    # document.onkeypress = @debounce console.log('hello world'), 300
    # @cursorChangePosSubscription = atom.workspace.getActiveTextEditor().onDidChangeCursorPosition throttled
    @activeItemSubscription = atom.workspace.onDidStopChangingActivePaneItem =>
      @prepareEditor()
    @prepareEditor()
    # @cursorChangePosSubscription = atom.workspace.getActiveTextEditor().onDidChangeCursorPosition @scrollPage.bind(this)
    @subscriptions.add atom.commands.add 'atom-workspace',
      'animated-page-scroll:page-up': => @scrollPage -1
      'animated-page-scroll:page-down': => @scrollPage 1
    # @cursorChangePosSubscription = @editor.onDidChangeCursorPosition @scrollPage.bind(this)

  prepareEditor: ->
    @cursorChangePosSubscription?.dispose()
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    editorElement = atom.views.getView editor
    @cursorChangePosSubscription = editor.onDidChangeCursorPosition @scrollPage.bind(this)
    # @cursorChangePosSubscription = @editor.onDidChangeCursorPosition @center.bind(this)

  deactivate: ->
    @subscriptions.dispose()
    for _, animation of @anims
      animation.onDidChangeCursorPositionSubscription?.dispose()
      animation.tween.kill()
    @anims = {}

  serialize: ->


  # debounce: (func, threshold, execAsap) ->
  #   timeout = null
  #   (args...) ->
  #     obj = this
  #     delayed = ->
  #       func.apply(obj, args) unless execAsap
  #       timeout = null
  #     if timeout
  #       clearTimeout(timeout)
  #     else if (execAsap)
  #       func.apply(obj, args)
  #     timeout = setTimeout delayed, threshold || 100


  scrollPage: (direction) ->
    editor = atom.workspace.getActiveTextEditor()

    half = Math.floor(editor.getRowsPerPage() / 2)
    curs = editor.getCursorScreenPosition()
    rows = curs.row - half
    targ = editor.getLineHeightInPixels() * (rows)
    rspm = rows # row speed modifier
    if rspm < 0
      rspm *= -1
    console.log('rspm = ' + rspm)
    if @getScrollRows() != 1 && rspm % @getScrollRows() != 0
      return
    rspm = Math.round(rspm / 35)

    # numRowsToScroll can be positive or negative depending on the direction (-1 or 1).
    numRowsToScroll = @anims[editor.id]?.numRowsToScroll || rows
    # numRowsToScroll = (@anims[editor.id]?.numRowsToScroll || 0) + ((@getScrollRows() || editor.getRowsPerPage()) * direction)
    targetScroll = {top: targ} # we want to go to cursor instead of cursor + page
    # targetScroll = {top: editor.getLineHeightInPixels() * (editor.getCursorScreenPosition().row - 2 + numRowsToScroll)}

    if @anims[editor.id]
      # if an animation was already started for the editor, update the tween target.
      @anims[editor.id].numRowsToScroll = numRowsToScroll
      @anims[editor.id].tween.updateTo targetScroll, true

    else
      editorView = atom.views.getView(editor)
      scroller = {top: editorView.getScrollTop()}

      @anims[editor.id] =
        # stop animation when a cursor was moved.
        onDidChangeCursorPositionSubscription: editor.onDidChangeCursorPosition (_) =>
          @stopAnimation @anims[editor.id]

        numRowsToScroll: numRowsToScroll

        tween: Tween.to scroller, Math.max(0, (@getScrollDuration() + (@getRowModifier() * rspm)) ),
          top: targetScroll.top
          # ease: Power1.easeInOut
          # ease: Power1.easeOut
          ease: Back.easeOut.config(0.4)
          # ease: Power3.easeOut
          # ease: Elastic.easeOut
          # ease: Power2.easeOut

          onUpdate: =>
            if editorView?
              editorView.setScrollTop scroller.top

              # stop animation upon scrolling to the top or bottom.
              # animation = @anims[editor.id]
              # if (animation.numRowsToScroll < 0 && editorView.getScrollTop() <= 0) || (animation.numRowsToScroll > 0 && editorView.getScrollBottom() >= editor.getLineHeightInPixels() * editor.getScreenLineCount())
              #   @stopAnimation animation

          onComplete: =>
            @anims[editor.id].onDidChangeCursorPositionSubscription.dispose()
            # we do not want to move the cursor down
            # editor.moveDown @anims[editor.id].numRowsToScroll
            delete @anims[editor.id]

  stopAnimation: (animation) ->
    animation.tween.seek animation.tween.duration(), false

  getScrollDuration: ->
    atom.config.get('animated-page-scroll.scrollDuration')

  getRowModifier: ->
    atom.config.get('animated-page-scroll.rowModifier')

  getScrollRows: ->
    atom.config.get('animated-page-scroll.scrollRows')
