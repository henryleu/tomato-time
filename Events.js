// Generated by CoffeeScript 1.6.3
(function() {
  var Events, breaker, container, eventSplitter, eventsApi, hasOwnProperty, idCounter, listenMethods, nativeForEach, nativeKeys, slice, triggerEvents, _apply, _each, _has, _keys, _once, _ref, _uniqueId;

  container = typeof window !== "undefined" && window !== null ? window : exports;

  container.tl = (_ref = container.tl) != null ? _ref : {};

  breaker = {};

  nativeKeys = Object.keys;

  nativeForEach = Array.prototype.forEach;

  hasOwnProperty = Object.prototype.hasOwnProperty;

  slice = Array.prototype.slice;

  _apply = function(t, s) {
    var k, v, _results;
    _results = [];
    for (k in s) {
      v = s[k];
      _results.push(t[k] = v);
    }
    return _results;
  };

  idCounter = 0;

  _uniqueId = function(prefix) {
    var id;
    id = ++idCounter + '';
    return prefix != null ? prefix : prefix + {
      id: id
    };
  };

  _each = function(obj, iterator, context) {
    if (obj == null) {
      return;
    }
    if (nativeForEach && obj.forEach === nativeForEach) {
      return obj.forEach(iterator, context);
    }
  };

  /*
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
  */


  _has = function(obj, key) {
    var proto;
    if (hasOwnProperty) {
      return hasOwnProperty.call(obj, key);
    } else {
      proto = obj.__proto__ || obj.constructor.prototype;
      return (prop in obj) && (!(prop in proto) || proto[prop] !== obj[prop]);
    }
  };

  _keys = nativeKeys != null ? nativeKeys : function(obj) {
    var key;
    if (obj !== Object(obj)) {
      throw new TypeError('Invalid object');
    }
    return (function() {
      var _results;
      _results = [];
      for (key in obj) {
        if (_has(obj, key)) {
          _results.push(key);
        }
      }
      return _results;
    })();
  };

  _once = function(func) {
    var ran;
    ran = false;
    return function() {
      var memo;
      if (ran) {
        return memo;
      }
      ran = true;
      memo = func.apply(this, arguments);
      func = null;
      return memo;
    };
  };

  eventSplitter = /\s+/;

  eventsApi = function(obj, action, name, rest) {
    var key, n, names, value, _i, _len;
    if (!name) {
      return true;
    }
    if (typeof name === 'object') {
      for (key in name) {
        value = name[key];
        obj[action].apply(obj, [key, value].concat(rest));
      }
      return false;
    }
    if (eventSplitter.test(name)) {
      names = name.split(eventSplitter);
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        n = names[_i];
        obj[action].apply(obj, [n].concat(rest));
      }
      return false;
    }
    return true;
  };

  triggerEvents = function(events, args) {
    var a1, a2, a3, ev, i, l, _results, _results1, _results2, _results3, _results4;
    i = -1;
    l = events.length;
    a1 = args[0];
    a2 = args[1];
    a3 = args[2];
    switch (args.length) {
      case 0:
        _results = [];
        while (++i < l) {
          _results.push((ev = events[i]).callback.call(ev.ctx));
        }
        return _results;
        break;
      case 1:
        _results1 = [];
        while (++i < l) {
          _results1.push((ev = events[i]).callback.call(ev.ctx, a1));
        }
        return _results1;
        break;
      case 2:
        _results2 = [];
        while (++i < l) {
          _results2.push((ev = events[i]).callback.call(ev.ctx, a1, a2));
        }
        return _results2;
        break;
      case 3:
        _results3 = [];
        while (++i < l) {
          _results3.push((ev = events[i]).callback.call(ev.ctx, a1, a2, a3));
        }
        return _results3;
        break;
      default:
        _results4 = [];
        while (++i < l) {
          _results4.push((ev = events[i]).callback.apply(ev.ctx, args));
        }
        return _results4;
    }
  };

  Events = tl.Events = {
    on: function(name, callback, context) {
      var events, _base;
      if (!eventsApi(this, 'on', name, [callback, context]) || !callback) {
        return this;
      }
      if (this._events == null) {
        this._events = {};
      }
      events = (_base = this._events)[name] != null ? (_base = this._events)[name] : _base[name] = [];
      events.push({
        callback: callback,
        context: context,
        ctx: context || this
      });
      return this;
    },
    once: function(name, callback, context) {
      var once, self;
      if (!eventsApi(this, 'once', name, [callback, context]) || !callback) {
        return this;
      }
      self = this;
      once = _once(function() {
        self.off(name, once);
        callback.apply(this, arguments);
      });
      once._callback = callback;
      return this.on(name, once, context);
    },
    off: function(name, callback, context) {
      var ev, events, n, names, retain, _i, _j, _len, _len1;
      if (!this._events || !eventsApi(this, 'off', name, [callback, context])) {
        return this;
      }
      if (!name && !callback && !context) {
        this._events = {};
        return this;
      }
      names = name ? [name] : _keys(this._events);
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        n = names[_i];
        name = n;
        if (events = this._events[name]) {
          this._events[name] = retain = [];
          if (callback || context) {
            for (_j = 0, _len1 = events.length; _j < _len1; _j++) {
              ev = events[_j];
              if ((callback && callback !== ev.callback && callback !== ev.callback._callback) || (context && context !== ev.context)) {
                retain.push(ev);
              }
            }
          }
          if (!retain.length) {
            delete this._events[name];
          }
        }
      }
      return this;
    },
    trigger: function(name) {
      var allEvents, args, events;
      if (!this._events) {
        return this;
      }
      args = slice.call(arguments, 1);
      if (!eventsApi(this, 'trigger', name, args)) {
        return this;
      }
      events = this._events[name];
      allEvents = this._events.all;
      if (events) {
        triggerEvents(events, args);
      }
      if (allEvents) {
        triggerEvents(allEvents, arguments);
      }
      return this;
    },
    stopListening: function(obj, name, callback) {
      var deleteListener, id, listeners;
      listeners = this._listeners;
      if (!listeners) {
        return this;
      }
      deleteListener = !name && !callback;
      if (typeof name === 'object') {
        callback = this;
      }
      if (obj) {
        (listeners = {})[obj._listenerId] = obj;
      }
      for (id in listeners) {
        listeners[id].off(name, callback, this);
        if (deleteListener) {
          delete this._listeners[id];
        }
      }
      return this;
    }
  };

  listenMethods = {
    listenTo: 'on',
    listenToOnce: 'once'
  };

  _each(listenMethods, function(implementation, method) {
    return Events[method] = function(obj, name, callback) {
      var id, listeners;
      listeners = this._listeners = this._listeners ? this._listeners : {};
      id = obj._listenerId = this._listenerId ? this._listenerId : _uniqueId('l');
      listeners[id] = obj;
      if (typeof name === 'object') {
        callback = this;
      }
      obj[implementation](name, callback, this);
      return this;
    };
  });

}).call(this);