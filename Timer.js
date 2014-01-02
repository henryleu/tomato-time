// Generated by CoffeeScript 1.6.3
(function() {
  var Crysto, EVENT, Events, STATUS, Timer, container, noop, _apply, _ref;

  container = typeof window !== "undefined" && window !== null ? window : exports;

  container.tl = (_ref = container.tl) != null ? _ref : {};

  noop = function() {};

  if (window.console == null) {
    window.console = {
      log: noop,
      info: noop,
      warn: noop,
      debug: noop,
      error: noop
    };
  }

  _apply = function(t, s) {
    var k, v, _results;
    _results = [];
    for (k in s) {
      v = s[k];
      _results.push(t[k] = v);
    }
    return _results;
  };

  Events = (function() {
    if (container.tl.Events) {
      return container.tl.Events;
    } else {
      throw new Error('Need tl.Events lib');
    }
  })();

  Crysto = (function() {
    if (container.tl.Crysto) {
      return container.tl.Crysto;
    } else {
      throw new Error('Need tl.Crysto lib');
    }
  })();

  STATUS = {
    running: 'r',
    stopped: 's'
  };

  EVENT = {
    start: 'start',
    stop: 'stop'
  };

  Timer = (function() {
    Timer.statuses = STATUS;

    Timer.events = EVENT;

    Timer.idCounter = 0;

    Timer.prototype.status = STATUS.stopped;

    Timer.prototype.o = {
      interval: 200
    };

    Timer.prototype.engine = null;

    Timer.prototype.events = null;

    Timer.prototype.job = null;

    function Timer(o) {
      this.id = ++Timer.idCounter;
      this.events = {};
      _apply(this.events, Events);
      this.job = {};
      this.config(o);
    }

    Timer.prototype.config = function(o) {
      this.o = {};
      _apply(this.o, Timer.prototype.o);
      if (o && o instanceof Object) {
        _apply(this.o, o);
      }
      if (o && o.engine) {
        this.internalEngine = false;
        return this.engine = o.engine;
      } else {
        this.internalEngine = true;
        return this.engine = new Crysto({
          interval: this.o.interval
        });
      }
    };

    Timer.prototype.start = function() {
      /* check state*/

      if (this.status === STATUS.running) {
        console.warn('the Timer[' + this.id + '] is running now, it cannot be started again until stopped');
        return;
      }
      /* update state*/

      this.status = STATUS.running;
      /* start crysto engine*/

      if (this.internalEngine) {
        this.engine.start();
      } else {
        if (this.engine.status !== Crysto.statuses.running) {
          console.warn('the external crysto engine is not running, so it needs to be started.');
        }
      }
      console.info('the Timer[' + this.id + '] is started');
      return this.events.trigger(EVENT.start);
    };

    Timer.prototype.stop = function() {
      /* check state*/

      if (this.status !== STATUS.running) {
        console.warn('the Timer[' + this.id + '] is not running now, no need to stop it');
        return;
      }
      /* update state*/

      this.status = STATUS.stopped;
      /* stop crysto engine*/

      if (this.internalEngine) {
        this.engine.stop();
      }
      console.info('the Timer[' + this.id + '] is stopped');
      return this.events.trigger(EVENT.stop);
    };

    Timer.prototype.onStart = function(callback, context) {
      return this.events.on(EVENT.start, callback, context);
    };

    Timer.prototype.offStart = function(callback) {
      return this.events.off(EVENT.start, callback);
    };

    Timer.prototype.onStop = function(callback, context) {
      return this.events.on(EVENT.stop, callback, context);
    };

    Timer.prototype.offStop = function(callback) {
      return this.events.off(EVENT.stop, callback);
    };

    Timer.prototype.job = function(jobId) {};

    return Timer;

  })();

  container.tl.Timer = Timer;

}).call(this);
