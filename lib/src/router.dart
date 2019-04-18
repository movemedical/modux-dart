import 'dart:async';
import 'dart:collection';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'action.dart';
import 'command.dart';
import 'middleware.dart';
import 'reducer.dart';
import 'store.dart';

part 'router.g.dart';

abstract class RouterPlugin<R> {
  set mutator(RouterServiceMutator mutator);

  R createRoute(RouteFuture future);

  Future push(ActiveRoute route);

  Future pushReplacement(ActiveRoute route);

  Future pushAndRemoveUntil(ActiveRoute route, bool test(R));

  Future<bool> pop(ActiveRoute active, dynamic result);

  bool canPop();

  void replace(ActiveRoute oldRoute, ActiveRoute newRoute);
}

typedef PlatformRouteBuilder = Function(RouteFuture);

class RouteDescriptor {
  final String key;
  final Store store;
  final RouteDispatcher dispatcher;
  final ModuxActions fromActions;
  final RouteActions toActions;
  PlatformRouteBuilder _platformBuilder;

  RouteFuture get future => _active?.future;

  ActiveRoute _active;

  ActiveRoute get active => _active;

  bool get isActive => _active != null;

  PlatformRouteBuilder get platformBuilder => _platformBuilder;

  set platformBuilder(PlatformRouteBuilder builder) {
    _platformBuilder = builder;
  }

  RouteDescriptor(
      this.key, this.store, this.dispatcher, this.fromActions, this.toActions);

  @override
  String toString() {
    return 'RouteDescriptor{key: $key, '
        'dispatcher: $dispatcher, '
        'fromActions: $fromActions, '
        'toActions: $toActions}';
  }
}

abstract class HasRouterActions {
  FieldDispatcher<BuiltList<String>> get stack;

  HasRouterState $mapState(Built<dynamic, dynamic> state);
}

abstract class HasRouterState {
  BuiltList<String> get stack;
}

class RouteConfigError extends Error {
  final String message;

  RouteConfigError(this.message);

  @override
  String toString() {
    return 'RouteConfigError {message: $message}';
  }
}

abstract class RouterRegistry {
  BuiltMap<String, RouteActions> get actionsByName;

  BuiltMap<Type, RouteActions> get actionsByType;

  BuiltMap<String, RouteDescriptor> get routesByName;

  BuiltSetMultimap<Type, RouteDescriptor> get routesByType;
}

class ReflectiveRouterRegistry implements RouterRegistry {
  final Store store;
  BuiltMap<String, RouteActions> _actionsByName;
  BuiltMap<Type, RouteActions> _actionsByType;
  BuiltMap<String, RouteDescriptor> _routesByName;
  BuiltSetMultimap<Type, RouteDescriptor> _routesByType;

  BuiltMap<String, RouteActions> get actionsByName => _actionsByName;

  BuiltMap<Type, RouteActions> get actionsByType => _actionsByType;

  BuiltMap<String, RouteDescriptor> get routesByName => _routesByName;

  BuiltSetMultimap<Type, RouteDescriptor> get routesByType => _routesByType;

  ReflectiveRouterRegistry(this.store) {
    final actionsByType = MapBuilder<Type, RouteActions>();
    final actionsByName = MapBuilder<String, RouteActions>();

    store.actions.$visitNested((n) {
      if (n is RouteActions) {
        actionsByName[n.$name] = n;
        final existing = actionsByType[n.$actionsType];
        if (existing != null)
          throw RouteConfigError('RouteActions Type '
              '[${n.$actionsType}] was injected multiple times \n'
              '1. ${existing.$name}\n'
              '2. ${n.$name}');
        actionsByType[n.$actionsType] = n;
      }
    });
    _actionsByName = actionsByName.build();
    _actionsByType = actionsByType.build();

    final routesByName = MapBuilder<String, RouteDescriptor>();
    final routesByType = SetMultimapBuilder<Type, RouteDescriptor>();
    store.actions.$visitCommands((owner, cmd) {
      if (cmd is RouteDispatcher) {
        // Find toActions.
        final from = cmd.$mapParent(store.actions);
        final actionsType = cmd.$toActionsType;
        final to = _actionsByType[actionsType];

        if (to == null)
          throw RouteConfigError('RouteCommand '
              '[${cmd.$name}] maps to '
              '[${cmd.$actionsType}] which is not a RouteActions');

        final entry = RouteDescriptor(cmd.$name, store, cmd, from, to);

        routesByName[cmd.$name] = entry;
        routesByType.add(cmd.$toActionsType, entry);
      }
    });

    _routesByName = routesByName.build();
    _routesByType = routesByType.build();
  }
}

class ActiveRoute {
  final dynamic platform;
  final RouteFuture future;
  final RouteDescriptor descriptor;
  Future platformFuture;

  ActiveRoute(this.platform, this.descriptor, this.future);

  RouteType get routeType => future?.routeType;

  RouteCommandAction get action => future?.routeAction;

  @override
  String toString() {
    return 'ActiveRoute{platform: $platform, future: $future}';
  }

  void _pushing() {
    try {
      descriptor?.toActions?.$pushing();
    } catch (e) {}
  }

  void _popping() {
    try {
      descriptor?.toActions?.$popping();
    } catch (e) {}
  }
}

/// Provides stack mutation for a RouterPlugin.
class RouterServiceMutator<T> {
  final RouterService service;

  RouterServiceMutator(this.service);

  void push(dynamic route) {
    service._didPush(route);
  }

  void pop(dynamic route) {
    service._didPop(route);
  }

  void replace(dynamic oldRoute, dynamic newRoute) {
    service._didReplace(oldRoute, newRoute);
  }

  void removed(dynamic route, dynamic previousRoute) {
    service._didRemove(route, previousRoute);
  }

  void sync() {
    service._syncState();
  }
}

class RouteWaiter extends LinkedListEntry<RouteWaiter> {
  RouteWaiter(this.matcher, Duration timeout) {
    if (timeout != null && timeout != Duration.zero) {
      _timer = Timer(timeout, () {
        if (completer.isCompleted) return;
        completer.completeError(TimeoutException('timeout'));
      });
    }
    completer.future.then((a) {
      _timer?.cancel();
      _timer = null;
      unlink();
    }, onError: (e) {
      _timer?.cancel();
      _timer = null;
      try {
        unlink();
      } catch (e) {}
    });
  }

  final bool Function(ActiveRoute r) matcher;
  final completer = Completer<ActiveRoute>();
  Timer _timer;

  void cancel() {
    if (completer.isCompleted) return;
    completer.completeError(CanceledException());
  }

  bool _maybeComplete(ActiveRoute r) {
    if (r.descriptor == null) return true;
    if (completer.isCompleted) return true;
    if (matcher(r)) {
      completer.complete(r);
      return true;
    }
    return false;
  }
}

///
class RouterService implements StoreService, RouterRegistry {
  final Store store;

  RouterServiceMutator _mutator;
  final _stack = List<ActiveRoute>();
  final _byPlatform = LinkedHashMap<dynamic, ActiveRoute>();
  final _waiters = LinkedList<RouteWaiter>();

  final HasRouterActions actions;
  RouterRegistry _registry;

  RouterRegistry get registry => _registry;

  RouterPlugin _plugin;

  RouterService(this.store, this.actions, {RouterRegistry registry})
      : _registry = registry {
    _mutator = RouterServiceMutator(this);
    if (_registry == null) {
      _registry = ReflectiveRouterRegistry(store);
    }
  }

  void install(RouterPlugin plugin) {
    if (_plugin != null)
      throw StateError('RouterPlugin [$_plugin] was already installed');

    _plugin = plugin;
    plugin.mutator = _mutator;
  }

  @override
  Type get keyType => RouterService;

  @override
  BuiltMap<String, RouteActions> get actionsByName => _registry.actionsByName;

  @override
  BuiltMap<Type, RouteActions> get actionsByType => _registry.actionsByType;

  @override
  BuiltMap<String, RouteDescriptor> get routesByName => _registry.routesByName;

  @override
  BuiltSetMultimap<Type, RouteDescriptor> get routesByType =>
      _registry.routesByType;

  bool canPop() => _plugin?.canPop() ?? false;

  bool isCurrent(RouteActions actions) {
    if (_stack.isEmpty) return false;
    return _stack.last.descriptor?.toActions == actions;
  }

  RouteDescriptor activeRouteByType(Type type) {
    final routes = routesByType[type];
    if (routes == null || routes.isEmpty) return null;
    for (final route in routes) {
      if (route.active != null) return route;
    }
    return null;
  }

  HasRouterState get state => actions.$mapState(store.state);

  /// Immutable copy of the active stack.
  BuiltList<ActiveRoute> get stack => BuiltList<ActiveRoute>(_stack);

  FutureOr<ActiveRoute> waitForActions(RouteActions actions,
      [Duration timeout = Duration.zero]) async {
    final descriptors = registry.routesByType[actions.$actionsType];
    if (descriptors == null || descriptors.isEmpty)
      throw StateError(
          'Type ${actions.$actionsType} has no routes in the registry.');
    return _doWait(RouteWaiter(
        (a) => a?.descriptor?.toActions?.$actionsType == actions.$actionsType,
        timeout));
  }

  FutureOr<ActiveRoute> waitForType(Type type,
      [Duration timeout = const Duration(seconds: 5)]) async {
    final descriptors = registry.routesByType[type];
    if (descriptors == null || descriptors.isEmpty)
      throw StateError('Type $type has no routes in the registry.');
    return await _doWait(RouteWaiter((a) {
      if (a?.descriptor?.toActions?.$actionsType == type ?? false) {
        return true;
      }
      if (a?.descriptor?.dispatcher?.$actionsType == type ?? false) {
        return true;
      }

      return false;
    }, timeout));
  }

  FutureOr<ActiveRoute> _doWait(RouteWaiter waiter) async {
    _waiters.add(waiter);
    for (int i = 0; i < _stack.length; i++) {
      final r = _stack[i];
      if (r.future == null) continue;
      if (waiter._maybeComplete(r)) return r;
    }
    return await waiter.completer.future;
  }

  /// Find the active route based on RouteDispatcher name.
  ActiveRoute activeOfName(String name) => _stack?.firstWhere(
      (a) =>
          // Test for dispatcher name.
          (a.descriptor?.dispatcher?.$name == name ?? false) ||
          // Test for toActions name.
          (a.descriptor?.toActions?.$name == name ?? false),
      orElse: () => null);

  int indexOfName(String name) {
    for (var i = 0; i < _stack.length; i++) {
      if (_stack[i]?.descriptor?.dispatcher?.$name == name ?? false) return i;
    }
    return -1;
  }

  /// Find the active route of a RouteActions type.
  ActiveRoute activeOfType(Type type) => _stack?.firstWhere(
      (a) => a.descriptor?.dispatcher?.$toActionsType == type ?? false,
      orElse: () => null);

  /// Find the active route of a platform route instance.
  ActiveRoute activeOfPlatform(dynamic platform) =>
      // Check the byPlatform map first.
      _byPlatform[platform] ??
      _stack?.firstWhere((e) => e.platform == platform ?? false,
          orElse: () => null);

  /// Get ActiveRoute by index in Stack.
  operator [](int index) =>
      index > -1 && index < _stack.length ? _stack[index] : null;

  int indexOfPlatform(dynamic route) {
    for (var i = 0; i < _stack.length; i++) {
      if (_stack[i].platform == route) return i;
    }
    return -1;
  }

  int indexOfType(Type type) {
    for (var i = 0; i < _stack.length; i++) {
      if (_stack[i]?.descriptor?.dispatcher?.$toActionsType == type ?? false)
        return i;
    }
    return -1;
  }

  ActiveRoute findRoute(bool test(ActiveRoute route),
      {bool ascending = false}) {
    if (ascending) {
      for (int i = 0; i < _stack.length; i++) {
        final route = _stack[i];
        if (test(route)) return route;
      }
    } else {
      for (int i = _stack.length - 1; i > -1; i--) {
        final route = _stack[i];
        if (test(route)) return route;
      }
    }
    return null;
  }

  @override
  Future init() async {}

  @override
  Future dispose() async {
    List.of(_waiters).forEach((w) => w.cancel());
  }

  /// Attempts to restore Router UI state on startup.
  Future inflate({Duration routeTimeout = const Duration(seconds: 5)}) async {
    final stack = state?.stack;
    if (stack == null) {
      actions.stack(BuiltList<String>());
      return;
    }
    if (stack.isEmpty) return;

    for (int i = 0; i < stack.length; i++) {
      final route = _registry.routesByName[stack[i]];
      if (route == null)
        throw StateError(
            'Inflation failed because Route type ${stack[i]} does not exist');

      // Start Route.
      final routeState = route.toActions.$mapState(store.state);
      final future = route.dispatcher(
          state: routeState,
          inflating: true,
          transitionDuration: Duration.zero);
      // Wait for platform to register.
      if (routeTimeout != null && routeTimeout != Duration.zero)
        await future._ack.future.timeout(routeTimeout);
      else
        await future._ack.future;
    }
  }

  void _didPush(dynamic route) {
    final index = indexOfPlatform(route);
    if (index != -1) return;
    final r = _byPlatform.remove(route);

    if (r == null) {
      _stack.add(ActiveRoute(route, null, null));
    } else {
      if (r.future != null && !r.future._ack.isCompleted) {
        r.future._ack.complete(r);
      }
      _stack.add(r);
    }
    _syncState();
  }

  void _didReplace(dynamic oldRoute, dynamic newRoute) {
    final index = indexOfPlatform(oldRoute);
    final n = _byPlatform.remove(newRoute);
    if (index == -1) {
      _stack.add(n);
      _syncState();
      return;
    }

    final o = _stack[index];
    _byPlatform.remove(oldRoute);

    o?.future?.complete(CommandResultCode.done);
    _stack[index] = n;
    if (n.future != null) {
      // Acknowledge
      if (!n.future._ack.isCompleted) {
        n.future._ack.complete(n);
      }
    }
    _syncState();
  }

  void _didRemove(dynamic platform, dynamic previousPlatform) {
    _byPlatform.remove(platform);
    final index = indexOfPlatform(platform);
    if (index == -1) return;

    final route = _stack.removeAt(index);
    final future = route.future;
    if (future != null) {
      future.complete(CommandResultCode.done);
    }
    _syncState();
  }

  void _didPop(dynamic platform) {
    // Ensure it's removed from byPlatform map.
    _byPlatform.remove(platform);

    // Find index in stack.
    final index = indexOfPlatform(platform);
    if (index == -1) {
      return;
    }
    if (index == _stack.length - 1) {
      try {
        final popped = _stack.removeLast();

        if (!(popped?.future?.isCompleted ?? true)) {
          popped?.future?.complete(CommandResultCode.done);
        }
      } finally {
        _syncState();
      }
      return;
    }

    final route = _stack[index];

    final truncated = List.of(_stack.sublist(index + 1));
    final l = _stack.length;
    for (int i = index; i < l; i++) {
      _stack.removeLast();
    }
    for (int i = truncated.length - 1; i > -1; i--) {
      _plugin?.pop(truncated[i], null);
    }

    _syncState();
  }

  void _execute(RouteFuture future) {
    final toActionsType = future.dispatcher.$toActionsType;

    // Ensure Route isn't already in the stack.
    if (_stack?.where((a) => a.descriptor != null)?.firstWhere(
            (a) => a.descriptor.toActions?.$actionsType == toActionsType,
            orElse: () => null) !=
        null) {
//      future.cancel('already exists');
      future.cancel();
      return;
    }

    dynamic platform;
    try {
      platform = _plugin?.createRoute(future);
    } catch (e, stackTrace) {
      future.complete(CommandResultCode.error, message: e?.toString());
      return;
    }

    if (platform == null) {
      future.complete(CommandResultCode.error,
          message: 'createRoute() returned null');
      return;
    }

    final route = ActiveRoute(platform, future.descriptor, future);
    _byPlatform[platform] = route;

    route._pushing();

    switch (future.routeAction) {
      case RouteCommandAction.push:
        route.platformFuture = _plugin?.push(route);
        break;

      case RouteCommandAction.replace:
        var replaceName = future.command?.payload?.predicateName ?? '';
        ActiveRoute replaceRoute = null;
        if (replaceName.isEmpty) {
          replaceRoute = _stack.isNotEmpty ? _stack.last : null;
        }

        if (replaceRoute != null) {
          _plugin?.replace(replaceRoute, route);
        } else {
          _plugin?.push(route);
        }
        break;

      case RouteCommandAction.pushReplacement:
        route.platformFuture = _plugin?.pushReplacement(route);
        break;

      case RouteCommandAction.pushAndRemoveUntil:
        ActiveRoute until = null;
        final untilName = future.command?.payload?.predicateName ?? '';
        if (untilName.isNotEmpty) {
          until = activeOfName(untilName)?.platform;
        }
        route.platformFuture = _plugin?.pushAndRemoveUntil(route, (p) {
          if (until == null) return false;
          return until.platform == p;
        });
        break;
    }

    if (route.platformFuture != null) {
      route.platformFuture?.then((n) {
        if (route.future?.isCompleted ?? false)
          route.future?.complete(CommandResultCode.done,
              response: route.future?.descriptor?.toActions?.resultOf(n));
      })?.catchError((e) {
        route.future?.complete(CommandResultCode.error, message: e?.toString());
      });
    }
  }

  void _done(RouteFuture future, CommandResult<RouteResult> result) {
    try {
      if (_stack.isEmpty) return;
      final index = _stack.indexOf(future.active);
      if (index < 0) {
        future.active?.descriptor?.toActions?.$deactivated?.call();
        return;
      }

      _stack[index]?._popping();

      // Sync.
      _plugin?.pop(future.active, result);
    } finally {
      _syncState();
    }
  }

  void _syncState() {
    final next = BuiltList<String>(_stack
        .map((a) => a.future?.dispatcher?.$name)
        .where((a) => a != null)
        .toList(growable: false));
    if (state?.stack != next) {
      actions?.stack(next);
    }
  }
}

///
abstract class RouteActions<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Result extends Built<Result, ResultBuilder>,
    ResultBuilder extends Builder<Result, ResultBuilder>,
    Actions extends RouteActions<State, StateBuilder, Result, ResultBuilder,
        Actions>> extends StatefulActions<State, StateBuilder, Actions> {
  bool get $isDialog => false;

  RouteType get $routeType => RouteType.page;

  /// Dispatched once the route has been acknowledged by the Platform Plugin.
  ActionDispatcher<Null> get $activated;

  /// Dispatched once the route has been popped/removed from the
  /// Platform Plugin.
  ActionDispatcher<Null> get $deactivated;

  ActionDispatcher<State> get $pushing;

  ActionDispatcher<Result> get $popping;

  RouteFuture<State, StateBuilder, Result, ResultBuilder, Actions, dynamic>
      get future =>
          $store.service<RouterService>().activeRouteByType(Actions)?.future
              as RouteFuture<State, StateBuilder, Result, ResultBuilder,
                  Actions, dynamic>;

  RouterService get $router => $store.service<RouterService>();

  bool $canPop() => $router.canPop();

  bool get $isCurrent => $router.isCurrent(this);

  Future<bool> $onWillPop() async {
    return true;
  }

  ResultBuilder $newResultBuilder();

  RouteResult<Result> resultOf(Result result) =>
      RouteResult<Result>((b) => b..value = result);

  bool $pop({Result result, void builder(ResultBuilder b)}) {
    final router = $router;
    if (router == null)
      throw StateError('RouterService not registered in store');

    final active = router.activeOfName($name);
    if (active == null) return false;

    if (active.platformFuture != null) {
      router._plugin?.pop(active, result);
      return true;
    }

    if (builder != null) {
      final b = $newResultBuilder();
      builder(b);
      result = b.build();
    }

    if (result == null) {
      result = $newResultBuilder().build();
    }

    active.future.complete(CommandResultCode.done,
        response: RouteResult<Result>((b) => b..value = result));

    return true;
  }

  @override
  void $reducer(ReducerBuilder reducer) {
    super.$reducer(reducer);

    reducer.nest(this);
  }

  @override
  void $middleware(MiddlewareBuilder builder) {
    super.$middleware(builder);

    builder.nest(this)
      ..add($activated, (api, next, action) {
        next(action);
        $didActivate(api.store, api.state);
      })
      ..add($deactivated, (api, next, action) {
        next(action);
        $didDeactivate(api.store, api.state);
      })
      ..add($pushing, (api, next, action) {
        next(action);
        $onPush(api.store, api.state);
//        final service = api.store.service<RouterService>();
      })
      ..add($popping, (api, next, action) {
        next(action);
        $onPop(api.store, api.state, action.payload);
//        final service = api.store.service<RouterService>();
      });
  }

  void $onPush(Store store, State state) {}

  void $onPop(Store store, State state, Result result) {}

  void $didActivate(Store store, State state) {}

  void $didDeactivate(Store store, State state) {}
}

@BuiltValueEnum(wireName: 'modux/RouteCommandAction')
class RouteCommandAction extends EnumClass {
  static const RouteCommandAction push = _$wirePush;
  static const RouteCommandAction pushReplacement = _$wirePushReplacement;
  static const RouteCommandAction pushAndRemoveUntil = _$wirePushAndRemoveUntil;
  static const RouteCommandAction popAndPush = _$wirePopAndPush;
  static const RouteCommandAction replace = _$wireReplace;

  const RouteCommandAction._(String name) : super(name);

  static BuiltSet<RouteCommandAction> get values => _$routeCommandActionValues;

  static RouteCommandAction valueOf(String name) =>
      _$routeActionKindValueOf(name);

  static Serializer<RouteCommandAction> get serializer =>
      _$routeCommandActionSerializer;
}

@BuiltValueEnum(wireName: 'modux/RouteType')
class RouteType extends EnumClass {
  static const RouteType page = _$wirePage;
  static const RouteType dialog = _$wireDialog;
  static const RouteType fullscreen = _$wireFullscreen;
  static const RouteType bottomSheet = _$wireBottomSheet;

  const RouteType._(String name) : super(name);

  static BuiltSet<RouteType> get values => _$routeTypeValues;

  static RouteType valueOf(String name) => _$routeTypeValueOf(name);

  static Serializer<RouteType> get serializer => _$routeTypeSerializer;
}

///
@BuiltValue(wireName: 'modux/RouteCommand')
abstract class RouteCommand<T>
    implements Built<RouteCommand<T>, RouteCommandBuilder<T>> {
  String get name;

  String get from;

  String get to;

  @nullable
  Duration get transitionDuration;

  @nullable
  RouteCommandAction get action;

  @nullable
  RouteType get routeType;

  @nullable
  String get predicateName;

  @nullable
  T get state;

  @nullable
  bool get inflating;

  RouteCommand._();

  factory RouteCommand([void updates(RouteCommandBuilder<T> builder)]) =
      _$RouteCommand<T>;

  static Serializer<RouteCommand> get serializer => _$routeCommandSerializer;
}

///
@BuiltValue(wireName: 'modux/RouteResult')
abstract class RouteResult<T>
    implements Built<RouteResult<T>, RouteResultBuilder<T>> {
  @nullable
  T get value;

  RouteResult._();

  factory RouteResult([void updates(RouteResultBuilder<T> builder)]) =
      _$RouteResult<T>;

  static Serializer<RouteResult> get serializer => _$routeResultSerializer;
}

/// RouteDispatcher
abstract class RouteDispatcher<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Result extends Built<Result, ResultBuilder>,
    ResultBuilder extends Builder<Result, ResultBuilder>,
    Actions extends RouteActions<State, StateBuilder, Result, ResultBuilder,
        Actions>,
    D extends RouteDispatcher<State, StateBuilder, Result, ResultBuilder,
        Actions, D>> extends NestedBuiltCommandDispatcher<
    RouteCommand<State>,
    RouteCommandBuilder<State>,
    State,
    StateBuilder,
    RouteResult<Result>,
    RouteResultBuilder<Result>,
    Result,
    ResultBuilder,
    D> {
  Type get $toActionsType => Actions;

  RouteFuture<State, StateBuilder, Result, ResultBuilder, Actions, D>
      get routeFuture =>
          $store.service<RouterService>().routesByName[$name]?.future;

  RouteCommand<State> create(
      {State state,
      StateBuilder Function(StateBuilder) builder,
      bool inflating = false,
      RouteType routeType,
      RouteCommandAction action,
      String predicateName,
      Duration transitionDuration,
      Duration timeout = Duration.zero}) {
    final service = $store.service<RouterService>();
    if (service == null) throw RouteConfigError('RouterService not registered');

    final route = service.routesByName[$name];
    if (route == null)
      throw RouteConfigError('Route named [${$name}] was not registered');

    if (builder != null) {
      state = builder(route.toActions.$initialBuilder)?.build() ??
          state ??
          route.toActions.$initial;
    }

    try {
      if (!route.toActions.$ensureState(state)) {
        throw StateError(
            'Command state [${route.toActions.$name}] cannot be initialized. '
            'Parent state [${route.toActions.$options.parent.name}] is null');
      }
    } catch (e) {
      // Ignore.
    }

    if (state == null) state = route.toActions.$initial;

    return (RouteCommandBuilder<State>()
          ..name = $options.name
          ..from = $options.parent?.name ?? ''
          ..to = route.toActions.$name
          ..state = state
          ..action = action
          ..predicateName = predicateName
          ..transitionDuration = transitionDuration
          ..routeType = routeType)
        .build();
  }

  RouteFuture<State, StateBuilder, Result, ResultBuilder, Actions, D> call(
      {State state,
      StateBuilder Function(StateBuilder) builder,
      bool inflating = false,
      RouteType routeType,
      RouteCommandAction action,
      String predicateName,
      Duration transitionDuration,
      Duration timeout = Duration.zero}) {
    final command = create(
        state: state,
        builder: builder,
        inflating: inflating,
        routeType: routeType,
        action: action,
        predicateName: predicateName,
        transitionDuration: transitionDuration,
        timeout: timeout);
    final future = $options.store.store.executeBuilt<
        RouteCommand<State>,
        RouteCommandBuilder<State>,
        State,
        StateBuilder,
        RouteResult<Result>,
        RouteResultBuilder<Result>,
        Result,
        ResultBuilder,
        D>(this, request: command, timeout: timeout);
    return future;
  }

  @override
  RouteFuture<State, StateBuilder, Result, ResultBuilder, Actions, D> newFuture(
      Command<RouteCommand<State>> command) {
    final service = $store.service<RouterService>();
    if (service == null) throw RouteConfigError('RouterService not registered');

    final route = service.routesByName[$name];
    if (route == null)
      throw RouteConfigError('Route named [${$name}] was not registered');

    return RouteFuture(service, route, this as D, command);
  }

  @override
  String toString() =>
      'RouteDispatcher{name: ${$name}, type: ${Actions}, toActions:${$toActionsType}}';
}

/// RouteFuture
class RouteFuture<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Result extends Built<Result, ResultBuilder>,
    ResultBuilder extends Builder<Result, ResultBuilder>,
    Actions extends RouteActions<State, StateBuilder, Result, ResultBuilder,
        Actions>,
    D extends RouteDispatcher<
        State,
        StateBuilder,
        Result,
        ResultBuilder,
        Actions,
        D>> extends CommandFuture<RouteCommand<State>, RouteResult<Result>, D> {
  RouteFuture(this.service, this.descriptor, D dispatcher,
      Command<RouteCommand<State>> command)
      : super(dispatcher, command) {
    _ack.future.then((v) {
      try {
        descriptor.toActions?.$activated?.call();
      } finally {
        service._waiters?.forEach((waiter) => waiter._maybeComplete(v));
      }
    });
  }

  final RouterService service;
  final RouteDescriptor descriptor;

  // Ack completer that completes once PlatformPlugin confirms route
  // by either pushing or replacing. Popping, removing or any other time
  // the future completes, the Ack will complete if not already.
  // When inflating, we wait for an Ack for each entry in the stack in
  // the proper order.
  final _ack = Completer<ActiveRoute>();

  ActiveRoute _active;
  ActiveRoute get active => _active;

  dynamic get platform => _active?.platform;

  RouteType get routeType =>
      command?.payload?.routeType ??
      descriptor.toActions.$routeType ??
      RouteType.page;

  RouteCommandAction get routeAction =>
      command?.payload?.action ?? RouteCommandAction.push;

  bool get isInflating => command?.payload?.inflating ?? false;

  bool tryComplete(Result result) {
    if (isCompleted) return false;
    complete(CommandResultCode.done,
        response: RouteResult((b) => b..value = result));
    return true;
  }

  @override
  void execute() {
    service._execute(this);
  }

  @override
  void done(CommandResult<RouteResult> result) {
    if (!_ack.isCompleted) _ack.complete();
    service?._done(this, result);
  }

  @override
  String toString() {
    return 'RouteFuture{command: $command, descriptor: $descriptor}';
  }
}
