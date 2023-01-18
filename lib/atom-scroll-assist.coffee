{CompositeDisposable} = require 'atom'
Tween = require 'gsap'

module.exports = atomScrollAssist =
  enabled: false
  config:
    scrollDuration:
      type: 'number'
      default: 0.35
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
      default: 1
      minimum: 1
      maximum: 50
      description: 'Row threshold for smoothing.'
      order: 3

  # https://raw.githubusercontent.com/halohalospecial/atom-animated-page-scroll/master/lib/animated-page-scroll.coffee
  # https://raw.githubusercontent.com/farcaller/typewriter-scroll/master/lib/typewriter-editor.coffee

  activate: (state) ->
    @counter = 0
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
    # @subscriptions.add atom.commands.add 'atom-workspace',
    #   'atom-scroll-assist:enable': => @enable
    #   'atom-scroll-assist:disable': => @disable
      # 'animated-page-scroll:page-down': => @scrollPage 1
    # @cursorChangePosSubscription = @editor.onDidChangeCursorPosition @scrollPage.bind(this)

  prepareEditor: ->
    @cursorChangePosSubscription?.dispose()
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    editorElement = atom.views.getView editor

    @cursorChangePosSubs


  disable: ->
    @enabled = false
    # @typewriterEditor.disable()
    alert('disabled')
    @deactivate()
    # @activeItemSubscription?.dispose()
    # @cursorChangePosSubscription?.dispose()

  enable: ->
    @enabled = true
    # @typewriterEditor.enable()
    alert('enabled')
    @activate()

  toggle: ->
    if @enabled then @disable() else @enable()

  deactivate: ->
    # alert('deactivated')
    @subscriptions.dispose()
    for _, animation of @anims
      animation.onDidChangeCursorPositionSubscription?.dispose()
      animation.tween.kill()
    @anims = {}
    @cursorChangePosSubscription?.dispose()

  #
  # disable: ->
  #   alert('disabled')
  #   @subscriptions.dispose()
  #   for _, animation of @anims
  #     animation.onDidChangeCursorPositionSubscription?.dispose()
  #     animation.tween.kill()
  #   @anims = {}
  #   @cursorChangePosSubscription?.dispose()
  #   # @activeItemSubscription?.dispose()
  #   # @cursorChangePosSubscription?.dispose()
  #
  # toggle: ->
  #   alert('toggle')

  serialize: ->


  scrollPage: (direction) ->
    @counter += 1
    console.log("counter: " + counter)
    if @counter < 10
        return
    else
        @counter = 0
        console.log("fire event")
    # this.preventDefault()
    editor = atom.workspace.getActiveTextEditor()

    half = Math.floor(editor.getRowsPerPage() / 2)
    curs = editor.getCursorScreenPosition()
    rows = curs.row - half
    targ = editor.getLineHeightInPixels() * (rows)
    rspm = rows # row speed modifier
    if rspm < 0
      rspm *= -1
    # if rspm < 10
    #   return
    # console.log('rspm = ' + rspm)
    if @getScrollRows() != 1 && rspm % @getScrollRows() != 0
      return
    rspm = Math.round(rspm / 35)

    numRowsToScroll = @anims[editor.id]?.numRowsToScroll || rows
    targetScroll = {top: targ} # we want to go to cursor instead of cursor + page

    if @anims[editor.id]
      # if an animation was already started for the editor, update the tween target.
      @anims[editor.id].numRowsToScroll = numRowsToScroll
      @anims[editor.id].tween.updateTo targetScroll, true

    else
      editorView = atom.views.getView(editor)
      scroller = {top: editorView.getScrollTop()}

      @anims[editor.id] =
        # smooth out animation when a cursor was moved.
        onDidChangeCursorPositionSubscription: editor.onDidChangeCursorPosition (_) =>
          @stopAnimation @anims[editor.id], editor

        numRowsToScroll: numRowsToScroll

        tween: Tween.to scroller, Math.max(0, (@getScrollDuration() + ( (@getRowModifier()) * rspm )) ),
          top: targ
          # ease: Power1.easeInOut
          ease: Power1.easeOut
          # ease: Back.easeOut.config(1.0)

          # ease: Back.easeInOut.config(0.8)
          # ease: Back.easeInOut.config(0.9)
          # ease: Back.easeOut.config(0.4)
          # ease: Power3.easeOut
          # ease: Elastic.easeOut
          # ease: Power2.easeOut

          onUpdate: =>
            if editorView?
              editorView.setScrollTop scroller.top

              # stop update if we hit top or bottom
              # return unless @animations[editor.id]
              # animation = @animations[editor.id]
              # if (animation.numRowsToScroll < 0 && editorView.getScrollTop() <= 0) || (animation.numRowsToScroll > 0 && editorView.getScrollBottom() >= editor.getLineHeightInPixels() * editor.getScreenLineCount())
              #   @stopAnimation animation, editor
                # animation.tween.seek animation.tween.duration(), false

          onComplete: =>
            @anims[editor.id].onDidChangeCursorPositionSubscription.dispose()
            delete @anims[editor.id]

  stopAnimation: (animation, editor) ->
    # editor = atom.workspace.getActiveTextEditor()

    half = Math.floor(editor.getRowsPerPage() / 2)
    curs = editor.getCursorScreenPosition()
    rows = curs.row - half
    targ = editor.getLineHeightInPixels() * (rows)
    rspm = rows # row speed modifier
    if rspm < 0
      rspm *= -1
    if rspm < 10
      return
    # console.log('rspm = ' + rspm)
    if @getScrollRows() != 1 && rspm % @getScrollRows() != 0
      return
    rspm = Math.round(rspm / 35)

    numRowsToScroll = @anims[editor.id]?.numRowsToScroll || rows
    targetScroll = {top: targ} # we want to go to cursor instead of cursor + page
    animation.tween.updateTo targetScroll, true
    # animation.tween.seek animation.tween.duration(), false

  getScrollDuration: ->
    atom.config.get('atom-scroll-assist.scrollDuration')

  getRowModifier: ->
    atom.config.get('atom-scroll-assist.rowModifier')

  getScrollRows: ->
    atom.config.get('atom-scroll-assist.scrollRows')
