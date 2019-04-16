import 'dart:async';
import 'dart:core';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'package:rxdart/rxdart.dart';
import 'package:logging/logging.dart';

import 'form.dart';
import 'action.dart';
import 'command.dart';
import 'middleware.dart';
import 'store_change.dart';
import 'typedefs.dart';
import 'service.dart';

///
abstract class StoreService {
  ///
  Store get store;

  ///
  Type get keyType;

  ///
  void init();

  ///
  void dispose();
}

abstract class StoreSubscriptions {
  void addSubscription(StoreSubscription s);

  void removeSubscription(StoreSubscription s);

  void disposeSubscriptions();
}

class StoreSubscriptionsImpl implements StoreSubscriptions {
  bool _subsIsClosing = false;
  final _subs = LinkedHashSet<StoreSubscription>();

  void addSubscription(StoreSubscription s) {
    _subs.add(s);
  }

  void removeSubscription(StoreSubscription s) {
    if (!_subsIsClosing) _subs.remove(s);
  }

  void disposeSubscriptions() {
    _subsIsClosing = true;
    _subs.forEach((s) => s.cancel());
    _subs.clear();
  }
}

mixin StoreSubscriptionsMixin implements StoreSubscriptions {
  final StoreSubscriptions _storeSubscriptions = StoreSubscriptionsImpl();

  void addSubscription(StoreSubscription s) =>
      _storeSubscriptions.addSubscription(s);

  void disposeSubscriptions() => _storeSubscriptions.disposeSubscriptions();

  void removeSubscription(StoreSubscription s) =>
      _storeSubscriptions.removeSubscription(s);
}

typedef Serializers SerializersFactory();

class StoreTester<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>> {
  StoreTester(this.store);

  final Store<State, StateBuilder, Actions> store;

  Future cancelAllFutures() async {
    final futures = <Future>[];
    store._futureMap.values.forEach((f) {
      futures.add(f);
      f.cancel();
    });
    if (futures.isNotEmpty) await Future.wait(futures);
  }
}

/// [Store] is the container of your state. It listens for actions,
/// invokes reducers, and publishes changes to the state
class Store<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>> {
  final Logger logger;
  final Serializers serializers;
  final HttpClientFactory httpFactory;
  final WebSocketFactory wsFactory;
  final StreamController<StoreChange<State, StateBuilder, dynamic>>
      _stateController = StreamController.broadcast();
  final StreamController<ActionEvent> _actionsController =
      StreamController.broadcast();
  final _services = LinkedHashMap<Type, dynamic>();
  final _dispatcherFutures = LinkedHashMap<String, DispatcherFutures>();
  final _futureMap = Map<String, CommandFuture>();
  final _actionMap = LinkedHashMap<String, _ActionEntry>();
  final _nestedMap = LinkedHashMap<String, _NestedEntry>();
  final _controllersMap = LinkedHashMap<String, ModuxController>();
  final _controllerStack = List<ModuxController>();
  final _subMixinStack = List<StoreSubscriptionsMixin>();
  JsonService _jsonService;
  StreamSubscription _subscription;

  // the current state
  State _state;
  Actions _actions;
  Dispatcher _dispatcher;

  Store(
    this.serializers,
    Actions actions,
    State defaultState, {
    this.httpFactory,
    this.wsFactory,
    Iterable<Middleware<State, StateBuilder, Actions>> middleware: const [],
    Function(Store<State, StateBuilder, Actions> store,
            Function(StoreService service) register)
        serviceFactory,
  }) : logger = Logger('ModuxStore') {
    // Set store reference on root Action Options which allows any
    // Actions or Dispatchers in the graph to use.
    actions.$options.store.store = this;

    _subscription = _actionsController.stream
        .listen(_data, onDone: _done, onError: _onError, cancelOnError: false);

    // set the initial state
    _state = defaultState;

    _actions = actions;

    final api = MiddlewareApi<State, StateBuilder, Actions>(this);

    final reducer = actions.$createReducer();
    assert(reducer != null, '\$createReducer() returned null');

    // setup the dispatch chain
    ActionHandler handler = (action) {
      var state = _state.rebuild((b) => reducer(_state, b, action));

      // if the state did not change do not publish an event
      if (_state == state) {
        try {
          if (!_actionsController.isClosed)
            _actionsController.add(ActionEvent(action, null));
        } catch (e, stackTrace) {
          logger.severe('ActionsStream.add()', e, stackTrace);
        }
        return;
      }

      // update the internal state and publish the change
      if (!_stateController.isClosed) {
        final change =
            StoreChange<State, StateBuilder, dynamic>(state, _state, action);
        try {
          _actionsController.add(ActionEvent(action, change));
        } catch (e, stackTrace) {
          logger.severe('ActionsStream.add()', e, stackTrace);
        }
        try {
          _stateController.add(change);
        } catch (e, stackTrace) {
          logger.severe('StateStream.add()', e, stackTrace);
        }
      }

      _state = state;
    };

    final middlewareList = List<Middleware<State, StateBuilder, Actions>>();
    middlewareList.add(_commandMiddleware);
    if (middleware != null) middlewareList.addAll(middleware);

    // Scope each function with the store's api
    Iterable<NextActionHandler> chain = middlewareList.map((m) => m(api));

    // combine each middleware
    NextActionHandler combinedMiddleware = chain.reduce(
        (composed, middleware) => (handler) => composed(middleware(handler)));

    // make the last middleware in the chain call the top-level reducer
    handler = combinedMiddleware(handler);

    // Call the handler when an action is dispatched.
    // Patch root dispatcher.
    _dispatcher = handler;
    actions.$options.store.dispatcher = handler;

    serviceFactory?.call(this, (service) {
      if (service == null) return;
      if (service is JsonService) {
        _jsonService = service;
        _services[JsonService] = service;
        _services[service.runtimeType] = service;
      }
      _services[service.keyType] = service;
      if (service is StoreSubscriptions) {
        _subMixinStack.add(service as StoreSubscriptionsMixin);
        try {
          service.init();
        } finally {
          _subMixinStack.removeLast();
        }
      } else {
        service.init();
      }
    });
  }

  Future<State> close() async {
    final state = this.state;
    await _cancelAllFutures();
    return state;
  }

  Future _cancelAllFutures() async {
    final futures = <Future>[];
    _futureMap.values.forEach((f) {
      futures.add(f);
      f.cancel();
    });
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  T service<T>() => _services[T] as T;

  JsonService get json =>
      _jsonService ??= DefaultJsonService(this, serializers);

  NextActionHandler Function(MiddlewareApi) get _commandMiddleware =>
      (MiddlewareApi api) => (ActionHandler next) => (Action action) {
            try {
              next(action);
            } catch (e, stackTrace) {
              logger.severe('CommandMiddleware.next()', e, stackTrace);
            }

            final commandPayload = action.payload;

            if (commandPayload is CommandPayload) {
              final command = commandPayload.payload;
              final dispatcher = commandPayload.dispatcher;

              DispatcherFutures futures = _dispatcherFutures[dispatcher.$name];

              if (futures == null) {
                return;
              }

              if (dispatcher.$cancel.name == action.name) {
                CommandFuture future =
                    futures.futures[action.payload?.toString() ?? ''];

                if (future != null) {
                  future.receivedCancel();
                } else {
                  future = _futureMap[action.payload?.toString()];
                  future?.receivedCancel();
                }
              }
            }
          };

  /// [dispose] removes closes both the dispatch and subscription stream
  Future<Null> dispose() async {
    _subscription?.cancel();
    await _stateController.close();
    await _actionsController.close();
    _state = null;
    _actions = null;
  }

  /// [state] returns the current state
  State get state => _state;

  /// [subscribe] returns a stream that will be dispatched whenever the
  /// state changes.
  Stream<StoreChange<State, StateBuilder, dynamic>> get stateStream =>
      _stateController.stream;

  Stream<ActionEvent> get actionsStream => _actionsController.stream;

  /// [actions] returns the synced actions
  Actions get actions => _actions;

  /// [nextState] is a stream which has a payload of the next state value,
  /// rather than the StoreChange event
  Stream<State> get nextState => stateStream
      .map((StoreChange<State, StateBuilder, dynamic> change) => change.next);

  /// [subStateStream] returns a stream to the state that is returned by the
  /// mapper function. For example: say my state object had a property count,
  /// then store.subStateStream((state) => state.count), would return a stream
  /// that fires whenever count changes.
  Stream<SubStateChange<State, StateBuilder, SubState, dynamic>>
      subStateStream<SubState>(
    StateMapper<State, StateBuilder, SubState> mapper,
  ) =>
          stateStream
              .map((c) =>
                  SubStateChange<State, StateBuilder, SubState, dynamic>(
                      mapper(c.prev), mapper(c.next), c))
              .where((c) => c.prev != c.next);

  /// [nextSubState] is a stream which has a payload of the next subState
  /// value, rather than the SubStateChange event.
  Stream<SubState> nextSubState<SubState>(
    StateMapper<State, StateBuilder, SubState> mapper,
  ) =>
      subStateStream(mapper).map(
          (SubStateChange<State, StateBuilder, SubState, dynamic> change) =>
              change.next);

  /// Waits for the next action from the specified ActionDispatcher to
  /// be dispatched.
  Future<ModuxEvent<P>> actionFuture<P>(ActionDispatcher<P> action,
          {Duration timeout = const Duration(seconds: 30),
          bool where(Action<P> action)}) async =>
      listen(action, null).toFuture(timeout);

  DispatcherFutures<REQ, RESP, D>
      futuresOf<REQ, RESP, D extends CommandDispatcher<REQ, RESP, D>>(
              D dispatcher) =>
          _dispatcherFutures[dispatcher.$name];

  /// Execute a Command.
  CommandFuture<REQ, RESP, D>
      executeCommand<REQ, RESP, D extends CommandDispatcher<REQ, RESP, D>>(
          D dispatcher, Command<REQ> command) {
    final future = dispatcher.newFuture(command);

    final name = dispatcher.$name;
    DispatcherFutures futures = _dispatcherFutures[name];

    if (futures == null) {
      futures = DispatcherFutures<REQ, RESP, D>(
          name, this, _dispatcherFutures, _futureMap, dispatcher);
      _dispatcherFutures[dispatcher.$name] = futures;
    }

    final existing = _futureMap[future.uid];
    futures.register(future);

    if (existing != null) {
      existing.cancel();
    }

    _futureMap[future.uid] = future;

    dispatcher.execute(command);

    future.start();
//    final state = dispatcher.$mapState(_state);
//    if (state == null) return Future.error('Command is null');
//    if (state.isCompleted) return Future.value(state.result);

    return future;
  }

  /// Execute a Command.
  CommandFuture<Cmd, Result, Actions>
      executeBuilt<
              Cmd extends Built<Cmd, CmdBuilder>,
              CmdBuilder extends Builder<Cmd, CmdBuilder>,
              CmdPayload extends Built<CmdPayload, CmdPayloadBuilder>,
              CmdPayloadBuilder extends Builder<CmdPayload, CmdPayloadBuilder>,
              Result extends Built<Result, ResultBuilder>,
              ResultBuilder extends Builder<Result, ResultBuilder>,
              ResultPayload extends Built<ResultPayload, ResultPayloadBuilder>,
              ResultPayloadBuilder extends Builder<ResultPayload,
                  ResultPayloadBuilder>,
              Actions extends NestedBuiltCommandDispatcher<
                  Cmd,
                  CmdBuilder,
                  CmdPayload,
                  CmdPayloadBuilder,
                  Result,
                  ResultBuilder,
                  ResultPayload,
                  ResultPayloadBuilder,
                  Actions>>(Actions dispatcher,
          {Cmd request,
          void builder(CmdBuilder b),
          Duration timeout = const Duration(seconds: 30),
          String id = ''}) {
    return executeCommand(
        dispatcher,
        Command<Cmd>((b) => b
          ..id = id == null || id.isEmpty ? uuid.next() : id
          ..payload = request
          ..timeout = timeout));
  }

  /// Execute a Command.
  CommandFuture<REQ, RESP, D>
      execute<REQ, RESP, D extends CommandDispatcher<REQ, RESP, D>>(
          D dispatcher, REQ request,
          {Duration timeout = const Duration(seconds: 30), String id = ''}) {
    return executeCommand(
        dispatcher,
        Command<REQ>((b) => b
          ..id = id == null || id.isEmpty ? uuid.next() : id
          ..payload = request
          ..timeout = timeout));
  }

  ///
  Future<CommandResult<RESP>>
      resultFuture<REQ, RESP, D extends CommandDispatcher<REQ, RESP, D>>(
          D dispatcher,
          {Duration timeout = const Duration(seconds: 30)}) async {
    final state = dispatcher.$mapState(_state);
    if (state == null) return Future.error('Command is null');
    if (state.isCompleted) return Future.value(state.result);

    return (await actionFuture(dispatcher.$result))?.value?.payload;
  }

  ///
  ModuxController get currentController =>
      _controllerStack.isNotEmpty ? _controllerStack.last : null;

  ///
  StoreSubscription<P> subscribe<P>(ActionDispatcher<P> dispatcher,
      {Duration timeout = Duration.zero}) {
    final actions = dispatcher.parent.mapper(this.actions);

    if (actions == null)
      throw 'ModuxActions not mapped for ActionDispatcher ${dispatcher.name}';

    var entry = _actionMap[dispatcher.name];
    if (entry == null) {
      entry = _ActionEntry(this, dispatcher.name, actions, dispatcher);
      _actionMap[dispatcher.name] = entry;
    }
    final sub = entry.register<P>(
        scope: currentController,
        dispatcher: dispatcher,
        handler: (_) {},
        mapper: (event) => Ok<P>(event.action.payload as P, event));

    if (_subMixinStack.isNotEmpty) _subMixinStack.last.addSubscription(sub);

    return sub;
  }

  ///
  StoreSubject<P> listen<P>(
      ActionDispatcher<P> dispatcher, Function(ModuxEvent<P>) handler,
      {Duration timeout = Duration.zero}) {
    final actions = dispatcher.parent.mapper(this.actions);

    if (actions == null) {
      throw 'ModuxActions not mapped for ActionDispatcher ${dispatcher.name}';
    }

    var entry = _actionMap[dispatcher.name];
    if (entry == null) {
      entry = _ActionEntry(this, dispatcher.name, actions, dispatcher);
      _actionMap[dispatcher.name] = entry;
    }
    final sub = entry.register<P>(
        scope: currentController,
        dispatcher: dispatcher,
        handler: handler,
        mapper: (event) => Ok<P>(event.action.payload as P, event));

    if (_subMixinStack.isNotEmpty) _subMixinStack.last.addSubscription(sub);

    return sub;
  }

  ///
  StoreSubject nestedStream(ModuxActions actions, Function(ModuxEvent) handler,
      {Duration timeout = Duration.zero}) {
    var entry = _nestedMap[actions.$name];
    if (entry == null) {
      entry = _NestedEntry(this, actions.$name, actions);
      _nestedMap[actions.$name] = entry;
    }
    final sub = entry.register(
        scope: currentController,
        handler: handler,
        mapper: (event) => Ok(event.action.payload, event));

    if (_subMixinStack.isNotEmpty) _subMixinStack.last.addSubscription(sub);

    return sub;
  }

  _onError(e, stackTrace) {
    logger.severe('', e, stackTrace);
  }

  _done() {
    if (_actionMap.isNotEmpty)
      (List()..addAll(_actionMap.values)).forEach((a) {});
    if (_nestedMap.isNotEmpty)
      (List()..addAll(_nestedMap.values)).forEach((a) {});
  }

  _data(ActionEvent event) {
    final action = event?.action;
    if (action == null) return;
    final name = action.name;
    if (name == null) return;

    final parts = name.split('.');
    final last = parts[parts.length - 1];
    final index = last.lastIndexOf('-');
    if (index < 0) return;

    var prev = '';
    for (var i = 0; i < parts.length - 1; i++) {
      prev = prev.isNotEmpty ? '$prev.${parts[i]}' : parts[i];
      final actions = _nestedMap[prev];
      if (actions != null) {
        actions.add(event);
      }
    }

    final actionsName = index == 0 ? '' : name.substring(0, index);
    _nestedMap[actionsName]?.add(event);

    _actionMap[name]?.add(event);
  }

  ModuxActions nestedOfName(String name) {
    if (name == null) return null;
    if (name.isEmpty) return this.actions;
    return actions.$nestedByRelativeName(name);
  }

  void dispatch<T>(Action<T> action) => _dispatcher?.call(action);

  ///
  ModuxController<State, StateBuilder, Actions, LocalState, LocalStateBuilder,
      LocalActions> controller<
          LocalState extends Built<LocalState, LocalStateBuilder>,
          LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
          LocalActions extends ModuxActions<LocalState,
              LocalStateBuilder, LocalActions>>(LocalActions actions,
      [Function() scoped]) {
    var scope = _controllersMap[actions.$name];
    if (scope == null) {
      scope = ModuxController<State, StateBuilder, Actions, LocalState,
          LocalStateBuilder, LocalActions>(this, actions, actions.$name);
      _controllersMap[scope.name] = scope;
    }
    _controllerStack.add(scope);
    try {
      scoped();
    } finally {
      _controllerStack.removeLast();
    }
    return scope;
  }

  ///
  ModuxController<State, StateBuilder, Actions, LocalState, LocalStateBuilder,
      LocalActions> controllerIfExists<
          LocalState extends Built<LocalState, LocalStateBuilder>,
          LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
          LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
              LocalActions>>(LocalActions actions) =>
      _controllersMap[actions.$name];

  bool hasController(ModuxActions actions) {
    if (actions == null) return false;
    return _controllersMap.containsKey(actions.$name);
  }
}

/// [ModuxController] is a stateful container of Streams and various
/// other services that are attached to an instance of ReduxActions
/// when 'activated'.
class ModuxController<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>,
    LocalState extends Built<LocalState, LocalStateBuilder>,
    LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
    LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
        LocalActions>> with StoreSubscriptionsMixin {
  final LocalActions actions;
  final String name;
  final Store<State, StateBuilder, Actions> store;
  final _props = LinkedHashMap();
  ModuxForm _form;

  ModuxController(this.store, this.actions, this.name);

  bool get isActive => store._controllersMap[name] == this;

  ModuxForm get form => _form;

  void registerForm(ModuxForm form) {
    _form = form;
  }

  void setProp(dynamic key, dynamic value) => _props[key] = value;

  void closeSilently() {
    try {
      close();
    } catch (e) {}
  }

  void close() {
    _props?.clear();

    final current = store._controllersMap[name];
    if (current == this) {
      store._controllersMap.remove(name);
    }

    disposeSubscriptions();
  }
}

///
class ActionEvent {
  final Action action;
  final StoreChange change;

  ActionEvent(this.action, this.change);

  String get name => action.name;

  ActionDispatcher get dispatcher => action?.dispatcher;

  dynamic get payload => action?.payload;
}

///
abstract class _SubscriptionEntry {
  final Store store;
  final String name;
  final ModuxActions actions;
  final subs = LinkedHashSet<StoreSubject>();

  _SubscriptionEntry(this.store, this.name, this.actions);

  StoreSubject<T> register<T>(
      {ModuxController scope,
      ActionDispatcher<T> dispatcher,
      bool Function(ActionEvent event) where,
      ModuxEvent<T> Function(ActionEvent event) mapper,
      Function(ModuxEvent<T>) handler,
      Duration timeout = Duration.zero}) {
    final sub = StoreSubject(scope, this, dispatcher, where, mapper, handler,
        timeout: timeout);
    subs.add(sub);
    scope?.addSubscription(sub);
//    scope?.subscriptions?.add(sub);
    return sub;
  }

  void _unregister<T>(StoreSubject<T> sub);

  void add(ActionEvent event) {
    subs?.forEach((s) => s._add(event));
  }
}

class _NestedEntry extends _SubscriptionEntry {
  _NestedEntry(Store store, String name, ModuxActions actions)
      : super(store, name, actions);

  @override
  void _unregister<T>(StoreSubject<T> sub) {
    subs.remove(sub);
    if (subs.isEmpty) store._nestedMap.remove(name);
    sub.owner?.removeSubscription(sub);
  }
}

class _ActionEntry extends _SubscriptionEntry {
  final ActionDispatcher dispatcher;

  _ActionEntry(Store store, String name, ModuxActions actions, this.dispatcher)
      : super(store, name, actions);

  @override
  void _unregister<T>(StoreSubject<T> sub) {
    subs.remove(sub);
    if (subs.isEmpty) store._actionMap.remove(name);
    sub.owner?.removeSubscription(sub);
  }
}

///
class CanceledException implements Exception {
  final String message;

  CanceledException([this.message]);
}

///
class ClosedException implements Exception {
  final String message;

  ClosedException([this.message]);
}

abstract class StoreSubscription<T> implements Observable<ModuxEvent<T>> {
  void cancel();
}

///
class StoreSubject<T> extends Subject<ModuxEvent<T>>
    implements StoreSubscription<T> {
  final ModuxController owner;
  final _SubscriptionEntry entry;
  final ActionDispatcher dispatcher;
  final bool Function(ActionEvent event) _where;
  final ModuxEvent<T> Function(ActionEvent event) mapper;
  final Function(ModuxEvent<T>) handler;
  final Duration duration;

  StreamSubscription _sub;

  StoreSubject._(
      this.owner,
      this.entry,
      this.dispatcher,
      this._where,
      this.mapper,
      this.handler,
      this.duration,
      StreamController<ModuxEvent<T>> ctrl,
      Observable<ModuxEvent<T>> observable)
      : super(ctrl, observable);

  void _start() {
    _sub = stream.listen(_data,
        onError: (e, stackTrace) => _error(e, stackTrace),
        onDone: _done,
        cancelOnError: false);
  }

  factory StoreSubject(
      ModuxController scope,
      _SubscriptionEntry entry,
      ActionDispatcher dispatcher,
      bool Function(ActionEvent event) _where,
      ModuxEvent<T> Function(ActionEvent event) mapper,
      Function(ModuxEvent<T>) handler,
      {Duration timeout = Duration.zero}) {
    // ignore: close_sinks
    final controller = StreamController<ModuxEvent<T>>.broadcast(
      sync: true,
    );

    Stream<ModuxEvent<T>> stream = controller.stream;

    if (timeout != Duration.zero) {
      stream = stream.timeout(timeout,
          onTimeout: (sink) => sink.add(Err<T>(TimeoutException('timeout'))));
    }

    final observable = Observable<ModuxEvent<T>>(stream);

    final subject = StoreSubject<T>._(scope, entry, dispatcher, _where, mapper,
        handler, timeout, controller, observable);

    subject._start();

    return subject;
  }

  /// Creates a new Observable.
//  Observable<ModuxEvent<T>> addObservable() {
//    if (isClosed) return Observable.error(ClosedException());
//    PublishSubject<ModuxEvent<T>> subject;
//    subject = PublishSubject<ModuxEvent<T>>(
//        onListen: () {
//          if (!isActive) {
//            if (subject != null) {
//              _subjects.remove(subject);
//            }
//            subject?.close();
//            subject = null;
//          }
//        },
//        onCancel: () {
//          if (subject != null) {
//            _subjects.remove(subject);
//            subject = null;
//          }
//          cancel();
//        },
//        sync: true);
//    if (_subjects == null) {
//      _subjects = LinkedHashSet<Subject<ModuxEvent<T>>>();
//    }
//    _subjects.add(subject);
//    return subject;
//  }

  /// Is this subscription Active?
  bool get isActive => !isClosed;

  /// Is there a timeout?
  bool get hasTimeout => timeout != null && timeout != Duration.zero;

  /// Is this subscription owned by a scope?
  bool get isScoped => owner != null;

  Future<ModuxEvent<T>> asFuture() async => toFuture(Duration.zero);

  ///
  Future<ModuxEvent<T>> toFuture(
      [Duration timeout = const Duration(seconds: 30)]) async {
    if (isClosed) {
      return Future.error(ClosedException());
    }

    final completer = Completer<ModuxEvent<T>>();

    var stream = this.stream;
    if (timeout != Duration.zero) {
      stream = stream.timeout(timeout,
          onTimeout: (sink) => sink.add(Err<T>(TimeoutException('timeout'))));
    }

    StreamSubscription subscription = null;
    subscription = stream.listen((event) {
      if (completer.isCompleted) return;
      try {
        completer.complete(event);
      } finally {
        subscription?.cancel();
        subscription = null;
      }
    }, onError: (e, stackTrace) {
      if (completer.isCompleted) return;
      try {
        completer.completeError(e, stackTrace);
      } finally {
        subscription?.cancel();
        subscription = null;
      }
    }, onDone: () {
      if (completer.isCompleted) return;
      try {
        completer.completeError(CanceledException());
      } finally {
        try {
          subscription?.cancel();
          subscription = null;
        } finally {
          _done();
        }
      }
    }, cancelOnError: true);

    return completer.future;
  }

  ModuxEvent<T> _map(ActionEvent event) {
    if (mapper == null) return null;
    try {
      if (!__where(event)) return null;
      return mapper(event);
    } catch (e, stackTrace) {
      return Err<T>(e, stackTrace, event);
    }
  }

  bool __where(ActionEvent event) => _where?.call(event) ?? true;

  void _error(dynamic e, [dynamic stackTrace]) {
    try {
//      _subjects?.forEach((s) => s.addError(e, stackTrace));
    } catch (e, stackTrace) {}
  }

  void _data(ModuxEvent<T> event) {
    try {
      handler?.call(event);
    } finally {
      try {
//        _subjects?.forEach((s) => s.add(event));
      } finally {
        if (event.isTimeout) {
          close();
        }
      }
    }
  }

  void _done() {
    cancel();
  }

  void _add(ActionEvent event) {
    if (!isActive) throw ClosedException();
    try {
      final value = _map(event);
      add(value);
    } catch (e, stackTrace) {
      try {
        add(Err<T>(e, stackTrace));
      } catch (e) {}
    }
  }

  @override
  Future<dynamic> close() async {
    if (isClosed) return;

//    if (_subjects != null && _subjects.isNotEmpty)
//      List.of(_subjects, growable: false).forEach((s) => s.close());
//
//    _subjects?.clear();

    _sub?.cancel();
    _sub = null;
    entry._unregister(this);

    try {
      super.close();
    } catch (e) {
      Future.microtask(() async {
        while (!isClosed) {
          await Future.delayed(Duration(milliseconds: 200));
          try {
            super.close();
            return;
          } catch (e) {}
        }
      });
    }
  }

  void cancel() => close();
}

///
abstract class ModuxEvent<T> {
  bool get isOk;

  bool get isErr;

  bool get isTimeout;

  bool get isCanceled;

  bool get isClosed;

  T get value;

  ActionEvent get event;

  static Err<T> timeout<T>(
      [TimeoutException e, dynamic stackTrace, ActionEvent event]) {
    return Err<T>(e ?? TimeoutException('timeout'), stackTrace, event);
  }
}

///
class Ok<T> implements ModuxEvent<T> {
  final T value;
  final ActionEvent event;

  Ok(this.value, [this.event]);

  @override
  bool get isOk => true;

  @override
  bool get isErr => false;

  @override
  bool get isTimeout => false;

  @override
  bool get isCanceled => false;

  @override
  bool get isClosed => false;

  @override
  String toString() {
    return 'Ok<$T>{ $value }';
  }
}

///
class Err<T> implements ModuxEvent<T> {
  final ActionEvent event;
  final dynamic error;
  final dynamic stackTrace;

  Err(this.error, [this.stackTrace, this.event]);

  @override
  T get value => null;

  @override
  bool get isOk => false;

  @override
  bool get isErr => true;

  @override
  bool get isTimeout => error is TimeoutException;

  @override
  bool get isCanceled => error is CanceledException;

  @override
  bool get isClosed => error is ClosedException;

  Duration get duration =>
      (error is TimeoutException) ? error.duration : Duration.zero;

  String get message => error?.toString();

  @override
  String toString() {
    return 'Err<$T>{error: $error${stackTrace != null ? ', stackTrace: $stackTrace' : ''}}';
  }
}

///
abstract class JsonService implements StoreService {
  @override
  Type get keyType => JsonService;

  Future<List<int>> serialize<T>(Serializer<T> serializer, T message);

  Future<T> deserialize<T>(Serializer<T> serializer, dynamic message);
}

@deprecated
class JsonServiceImpl extends DefaultJsonService {
  JsonServiceImpl(Store store, Serializers serializers)
      : super(store, serializers);
}

///
class DefaultJsonService extends JsonService {
  final Store store;
  final Serializers serializers;

  DefaultJsonService(this.store, this.serializers);

  @override
  void init() {}

  @override
  void dispose() {}

  @override
  Future<List<int>> serialize<T>(Serializer<T> serializer, T message) async {
    return Future.value(utf8
        .encode(json.encode(serializers.serializeWith(serializer, message))));
  }

  @override
  Future<T> deserialize<T>(Serializer<T> serializer, dynamic message) async {
    dynamic d;

    if (message is String) {
      d = json.decode(message);
    } else if (message is List<int>) {
      d = json.decode(utf8.decode(message));
    }

    if (d == null) {
      d = List();
    }

    return serializers.deserializeWith(serializer, d);
  }
}
