Tween = require 'gsap'


module.exports =
  enable: ->
    @anims = {}
    # @subscriptions = new CompositeDisposable

    @activeItemSubscription = atom.workspace.onDidStopChangingActivePaneItem =>
      @prepareEditor()
    @prepareEditor()

  disable: ->
    # @subscriptions.dispose()
    for _, animation of @anims
      animation.onDidChangeCursorPositionSubscription?.dispose()
      animation.tween.kill()
    @anims = {}

    @activeItemSubscription?.dispose()
    @cursorChangePosSubscription?.dispose()

  # center: ->
  #   halfScreen = Math.floor(@editor.getRowsPerPage() / 2)
  #   cursor = @editor.getCursorScreenPosition()
  #   position = @editor.getLineHeightInPixels() * (cursor.row - halfScreen)
  #   # Timeout needed since position changes after ::onDidChangeCursorPosition on moving with keys
  #   setTimeout => @editorElement.setScrollTop position, 1

  prepareEditor: ->
    @cursorChangePosSubscription?.dispose()
    @editor = atom.workspace.getActiveTextEditor()
    return unless @editor
    @editorElement = atom.views.getView @editor
    # @cursorChangePosSubscription = @editor.onDidChangeCursorPosition @center.bind(this)
    # modded hook
    @cursorChangePosSubscription = @editor.onDidChangeCursorPosition @scrollPage.bind(this)

  # extra funcs

  scrollPage: (direction) ->
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
