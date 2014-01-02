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

STATUS =
  running: 'r' # running
  stopped: 's' # stopped
EVENT =
  start: 'start'
  stop: 'stop'
  interval: 'interval'

class Crysto
  @statuses: STATUS
  @events: EVENT
  status: STATUS.stopped
  o:
    interval: 200 #default interval is 200
  events: null # tl.Events object as observable object
  timerHandle: null # the handle id the window.setInterval(..) returns
  startTime: -1
  stopTime: -1
  passed: 0 # milliseconds the time has passed from start.
  nowDate: null # current time's Date object which is set on each interval callback
  now: 0 # current time's milliseconds which is set on each interval callback
  intervalRounds: 0 # how many times interval has run.
  passedOffset: 0 # it means that passed - intervalRounds * interval

  constructor: (o)->
    this.events = {}
    _apply this.events, Events
    if o
      this.config(o)
      this.reset()

  config: (o) ->
    if o and o instanceof Object
      this.o = {}
      _apply(this.o, Crysto.prototype.o)
      _apply(this.o, o)
    else
      throw Error('needs options object for configuring Crysto')

  reset: ->
    if this.status is STATUS.running
      console.warn('the Crysto[' + this.timerHandle + '] is running now, it cannot be reset')
      return
    console.info('the Crysto[' + this.timerHandle + '] is reset')

    ###
    Init state to prepare for new starting
    ###
    this.status = STATUS.stopped
    this.timerHandle = -1
    this.nowDate = null
    this.now = -1
    this.startTime = -1
    this.stopTime = -1
    this.passed = 0
    this.intervalRounds = 0
    this.passedOffset = 0

  start: ->
    if this.status is STATUS.running
      console.warn('the Crysto[' + this.timerHandle + '] is running now, it cannot be started again until stopped')
      return

    this.status = STATUS.running
    this.nowDate = new Date()
    this.now = this.nowDate.getTime()
    this.startTime = this.now

    ###
    Init state for starting
    ###
    this.timerHandle = -1
    this.stopTime = -1
    this.passed = 0
    this.intervalRounds = 0
    this.passedOffset = 0

    me = this
    intervalFn = ->
      if me.status isnt STATUS.running
        console.warn('the Crysto[' + me.timerHandle + '] is already stopped, no more intervals')
        return
      else
        me.intervalProcessor()

    this.timerHandle = window.setInterval intervalFn, this.o.interval
    console.info('the Crysto[' + this.timerHandle + '] is started')
    this.events.trigger(EVENT.start)

  stop: ->
    if this.status isnt STATUS.running
      console.warn('the Crysto[' + this.timerHandle + '] is not running now, no need to stop it')
      return
    this.status = STATUS.stopped
    this.nowDate = new Date()
    this.now = this.nowDate.getTime()
    this.stopTime = this.now
    this.passed = this.now - this.startTime
    window.clearInterval(this.timerHandle)
    console.info('the Crysto[' + this.timerHandle + '] is stopped')
    this.events.trigger(EVENT.stop)

  intervalProcessor: ->
    this.nowDate = new Date()
    this.now = this.nowDate.getTime()
    this.passed = this.now - this.startTime
    this.intervalRounds++
    this.passedOffset = this.passed - this.intervalRounds * this.o.interval
    this.events.trigger(EVENT.interval)

  on: (event, callback, context) ->
    this.support(event) if event
    this.events.on(event, callback, context)

  off: (event, callback, context) ->
    this.support(event) if event
    this.events.off(event, callback, context)

  support: (event) ->
    event = event.substring(0, i) if i=event.indexOf(':')!=-1
    if EVENT[event]
      return true
    else
      console.warn('Crysto does not support event: #{event}')
      return false
container.tl.Crysto = Crysto