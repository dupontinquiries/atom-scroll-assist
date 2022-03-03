{CompositeDisposable} = require 'atom'
typewriterMode = require "./module"


module.exports = atomScrollAssist =
  typewriterMode: typewriterMode
  subscriptions: null
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
    autoToggle:
      type: 'boolean'
      default: true
      order: 4

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      "typewriter-scroll:toggle": => @toggle()
      "typewriter-scroll:enable": => @enable()
      "typewriter-scroll:disable": => @disable()
    if atom.config.get 'atom-scroll-assist.autoToggle'
      @toggle()

  deactivate: ->
    @enabled = false
    @subscriptions.dispose()
    @typewriterMode.disable()

  disable: ->
    @enabled = false
    @typewriterMode.disable()

  enable: ->
    @enabled = true
    @typewriterMode.enable()

  toggle: ->
    if @enabled then @disable() else @enable()
