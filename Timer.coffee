container = window ? exports
container.tl = container.tl ? {}

noop = ->
window.console ?=
  log: noop
  info: noop
  warn: noop
  debug: noop
  error: noop

# light-copy object's properties in first layer
_apply = (t, s) -> t[k] = v for k, v of s

Events = if container.tl.Events then container.tl.Events else throw new Error('Need tl.Events lib')
Crysto = if container.tl.Crysto then container.tl.Crysto else throw new Error('Need tl.Crysto lib')

STATUS =
  running: 'r' # running
  stopped: 's' # stopped
EVENT =
  start: 'start'
  stop: 'stop'

class Timer
  @statuses: STATUS
  @events: EVENT
  @idCounter: 0
  status: STATUS.stopped
  o:
    interval: 200 #default interval is 200
  engine: null # crysto engine for the timer
  events: null # tl.Events object as observable object
  job: null # all jobs map such as clock, countdown, countup, stopwatch

  constructor: (o)->
    this.id = ++Timer.idCounter
    this.events = {}
    _apply this.events, Events
    this.job = {}
    this.config(o)

  config: (o) ->
    this.o = {}
    _apply(this.o, Timer.prototype.o)
    _apply(this.o, o) if o and o instanceof Object

    if o and o.engine
      this.internalEngine = false
      this.engine = o.engine
    else
      this.internalEngine = true
      this.engine = new Crysto({interval: this.o.interval})

  start: ->
    ### check state ###
    if this.status is STATUS.running
      console.warn('the Timer[' + this.id + '] is running now, it cannot be started again until stopped')
      return

    ### update state ###
    this.status = STATUS.running

    ### start crysto engine ###
    if this.internalEngine
      this.engine.start()
    else
      if this.engine.status isnt Crysto.statuses.running
        console.warn('the external crysto engine is not running, so it needs to be started.')

    console.info('the Timer[' + this.id + '] is started')
    this.events.trigger(EVENT.start)

  stop: ->
    ### check state ###
    if this.status isnt STATUS.running
      console.warn('the Timer[' + this.id + '] is not running now, no need to stop it')
      return

    ### update state ###
    this.status = STATUS.stopped

    ### stop crysto engine ###
    if this.internalEngine
      this.engine.stop()

    console.info('the Timer[' + this.id + '] is stopped')
    this.events.trigger(EVENT.stop)

  onStart: (callback, context) ->
    this.events.on(EVENT.start, callback, context)

  offStart: (callback) ->
    this.events.off(EVENT.start, callback)

  onStop: (callback, context) ->
    this.events.on(EVENT.stop, callback, context)

  offStop: (callback) ->
    this.events.off(EVENT.stop, callback)

  job: (jobId)->

container.tl.Timer = Timer