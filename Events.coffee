container = window ? exports
container.tl = container.tl ? {}


breaker = {}
nativeKeys         = Object.keys # TODO: make it IE-compatible
nativeForEach      = Array.prototype.forEach
hasOwnProperty     = Object.prototype.hasOwnProperty
slice              = Array.prototype.slice

# light-copy object's properties in first layer
_apply = (t, s) -> t[k] = v for k, v of s

idCounter = 0
_uniqueId = (prefix) ->
  id = ++idCounter + ''
  return prefix ? prefix + id : id

# The cornerstone, an `each` implementation, aka `forEach`.
# Handles objects with the built-in `forEach`, arrays, and raw objects.
# Delegates to **ECMAScript 5**'s native `forEach` if available.
_each = (obj, iterator, context) ->
  return if not obj?
  if nativeForEach and obj.forEach is nativeForEach
    obj.forEach(iterator, context)

###
_each = (obj, iterator, context) ->
    return if (obj == null)
    if nativeForEach and obj.forEach is nativeForEach
      obj.forEach(iterator, context)
    else if typeof obj.length=='number'
      for item, i in obj
        if iterator.call(context, item, i, obj) == breaker
          break
    else
      for key of obj
        if _has(obj, key)
          return if iterator.call(context, obj[key], key, obj) is breaker
###

# Shortcut function for checking if an object has a given property directly
# on itself (in other words, not on a prototype).
_has = (obj, key) ->
  if hasOwnProperty
    return hasOwnProperty.call obj, key
  else
    proto = obj.__proto__ || obj.constructor.prototype;
    return (prop of obj) and (not (prop of proto) or proto[prop] isnt obj[prop])

# Retrieve the names of an object's properties.
# Delegates to **ECMAScript 5**'s native `Object.keys`
_keys = nativeKeys ? (obj) ->
  throw new TypeError('Invalid object') if obj isnt Object(obj) # TODO
  return (key for key of obj when _has(obj, key))

_once = (func) ->
  ran = false
  return ->
    return memo if ran
    ran = true
    memo = func.apply(this, arguments)
    func = null
    return memo

# Regular expression used to split event strings.
eventSplitter = /\s+/

# Implement fancy features of the Events API such as multiple event
# names `"change blur"` and jQuery-style event maps `{change: action}`
# in terms of the existing API.
eventsApi = (obj, action, name, rest) ->
  return true if not name

  # Handle event maps.
  if typeof name is 'object'
    obj[action].apply(obj, [key, value].concat(rest)) for key, value of name
    return false

  # Handle space separated event names.
  if eventSplitter.test(name)
    names = name.split(eventSplitter)
    obj[action].apply(obj, [n].concat(rest)) for n in names
    return false
  return true


# A difficult-to-believe, but optimized internal dispatch function for
# triggering events. Tries to keep the usual cases speedy (most internal
# tl events have 3 arguments).
triggerEvents = (events, args) ->
  i = -1
  l = events.length
  a1 = args[0]
  a2 = args[1]
  a3 = args[2]
  switch args.length
    when  0 then (ev = events[i]).callback.call(ev.ctx) while ++i < l
    when  1 then (ev = events[i]).callback.call(ev.ctx, a1) while ++i < l
    when  2 then (ev = events[i]).callback.call(ev.ctx, a1, a2) while ++i < l
    when  3 then (ev = events[i]).callback.call(ev.ctx, a1, a2, a3) while ++i < l
    else  (ev = events[i]).callback.apply(ev.ctx, args) while ++i < l

Events = tl.Events =

  # Bind an event to a `callback` function. Passing `"all"` will bind
  # the callback to all events fired.
  on: (name, callback, context) ->
    return this if not eventsApi(this, 'on', name, [callback, context]) or not callback
    this._events ?= {}
    events = this._events[name] ?= []
    events.push({callback: callback, context: context, ctx: context or this})
    return this

  # Bind an event to only be triggered a single time. After the first time
  # the callback is invoked, it will be removed.
  once: (name, callback, context) ->
    return this if not eventsApi(this, 'once', name, [callback, context]) or not callback
    self = this
    once = _once( ->
      self.off(name, once)
      callback.apply(this, arguments)
      return
    )
    once._callback = callback
    return this.on(name, once, context)

  # Remove one or many callbacks. If `context` is null, removes all
  # callbacks with that function. If `callback` is null, removes all
  # callbacks for the event. If `name` is null, removes all bound
  # callbacks for all events.
  off: (name, callback, context)->
    return this if not this._events or not eventsApi(this, 'off', name, [callback, context])
    if not name and not callback and not context
      this._events = {}
      return this

    names = if name then [name] else _keys(this._events)
    for n in names
      name = n
      if events = this._events[name]
        this._events[name] = retain = []
        if callback or context
          for ev in events
            retain.push(ev) if (callback and callback isnt ev.callback and callback isnt ev.callback._callback) or (context and context isnt ev.context)
        delete this._events[name] if not retain.length
    return this

  # Trigger one or many events, firing all bound callbacks. Callbacks are
  # passed the same arguments as `trigger` is, apart from the event name
  # (unless you're listening on `"all"`, which will cause your callback to
  # receive the true name of the event as the first argument).
  trigger: (name) ->
    return this if not this._events
    args = slice.call(arguments, 1)
    return this if not eventsApi(this, 'trigger', name, args)
    events = this._events[name]
    allEvents = this._events.all
    triggerEvents(events, args) if events
    triggerEvents(allEvents, arguments) if allEvents
    return this

  # Tell this object to stop listening to either specific events ... or
  # to every object it's currently listening to.
  stopListening: (obj, name, callback) ->
    listeners = this._listeners
    return this if not listeners
    deleteListener = not name and not callback
    callback = this if typeof name is 'object'
    (listeners = {})[obj._listenerId] = obj if obj
    for id of listeners
      listeners[id].off(name, callback, this)
      delete this._listeners[id] if deleteListener
    return this

listenMethods = {listenTo: 'on', listenToOnce: 'once'}

# Inversion-of-control versions of `on` and `once`. Tell *this* object to
# listen to an event in another object ... keeping track of what it's
# listening to.
_each listenMethods, (implementation, method) ->
  Events[method] = (obj, name, callback) ->
    listeners = this._listeners = if this._listeners then this._listeners else {}
    id = obj._listenerId = if this._listenerId then this._listenerId else _uniqueId('l')
    listeners[id] = obj
    callback = this if typeof name is 'object'
    obj[implementation](name, callback, this)
    return this