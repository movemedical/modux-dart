import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:logging/logging.dart';

import 'dart:collection';

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

  bool pop(ActiveRoute active, CommandResult<RouteResult> result);

  bool canPop();

  Future replace(ActiveRoute oldRoute, ActiveRoute newRoute);
}

typedef PlatformRouteBuilder = Function(RouteFuture);

class RouteEntry {
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

  RouteEntry(
      this.key, this.store, this.dispatcher, this.fromActions, this.toActions);
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

  BuiltMap<String, RouteEntry> get routesByName;

  BuiltSetMultimap<Type, RouteEntry> get routesByType;
}

class ReflectiveRouterRegistry implements RouterRegistry {
  final Store store;
  BuiltMap<String, RouteActions> _actionsByName;
  BuiltMap<Type, RouteActions> _actionsByType;
  BuiltMap<String, RouteEntry> _routesByName;
  BuiltSetMultimap<Type, RouteEntry> _routesByType;

  BuiltMap<String, RouteActions> get actionsByName => _actionsByName;

  BuiltMap<Type, RouteActions> get actionsByType => _actionsByType;

  BuiltMap<String, RouteEntry> get routesByName => _routesByName;

  BuiltSetMultimap<Type, RouteEntry> get routesByType => _routesByType;

  ReflectiveRouterRegistry(this.store) {
    final actionsByType = MapBuilder<Type, RouteActions>();
    final actionsByName = MapBuilder<String, RouteActions>();

    store.actions.$forEachNested((n) {
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

    final routesByName = MapBuilder<String, RouteEntry>();
    final routesByType = SetMultimapBuilder<Type, RouteEntry>();
    store.actions.$forEachCommand(store, (owner, cmd) {
      if (cmd is RouteDispatcher) {
        // Find toActions.
        final from = cmd.$mapParent(store.actions);
        final actionsType = cmd.$toActionsType;
        final to = _actionsByType[actionsType];

        if (to == null)
          throw RouteConfigError('RouteCommand '
              '[${cmd.$name}] maps to '
              '[${cmd.$actionsType}] which is not a RouteActions');

        final entry = RouteEntry(cmd.$name, store, cmd, from, to);

        routesByName[cmd.$name] = entry;
        routesByType.add(cmd.$actionsType, entry);
      }
    });

    _routesByName = routesByName.build();
    _routesByType = routesByType.build();
  }
}

class ActiveRoute {
  final dynamic platform;
  final RouteFuture future;
  final RouteEntry entry;

  ActiveRoute(this.platform, this.entry, this.future);

  RouteType get routeType => future?.routeType;

  RouteCommandAction get action => future?.routeAction;

  void _activated() {
    try {
      entry?.toActions?.$activated();
    } catch (e) {}
  }

  void _deactivated() {
    try {
      entry?.toActions?.$deactivated();
    } catch (e) {}
  }

  void _pushing() {
    try {
      entry?.toActions?.$pushing();
    } catch (e) {}
  }

  void _popping() {
    try {
      entry?.toActions?.$popping();
    } catch (e) {}
  }
}

/// Provides stack mutation for a RouterPlugin.
class RouterServiceMutator<T> {
  final RouterService service;

  RouterServiceMutator(this.service);

  void push(dynamic route) {
    service._push(route);
  }

  void pop(dynamic route) {
    service._pop(route);
  }

  void replace(dynamic oldRoute, dynamic newRoute) {
    service._replace(oldRoute, newRoute);
  }

  void sync() {
    service._syncState();
  }
}

///
class RouterService implements StoreService, RouterRegistry {
  final Store store;

  RouterServiceMutator _mutator;
  final _stack = List<ActiveRoute>();
  final _byPlatform = LinkedHashMap<dynamic, ActiveRoute>();

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
  BuiltMap<String, RouteEntry> get routesByName => _registry.routesByName;

  @override
  BuiltSetMultimap<Type, RouteEntry> get routesByType => _registry.routesByType;

  RouteEntry activeRouteByType(Type type) {
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

  /// Find the active route based on RouteDispatcher name.
  ActiveRoute activeOfName(String name) =>
      _stack?.firstWhere((a) => a.entry?.dispatcher?.$name == name ?? false,
          orElse: () => null);

  int indexOfName(String name) {
    for (var i = 0; i < _stack.length; i++) {
      if (_stack[i]?.entry?.dispatcher?.$name == name ?? false) return i;
    }
    return -1;
  }

  /// Find the active route of a RouteActions type.
  ActiveRoute activeOfType(Type type) => _stack?.firstWhere(
      (a) => a.entry?.dispatcher?.$toActionsType == type ?? false,
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
      if (_stack[i]?.entry?.dispatcher?.$toActionsType == type ?? false)
        return i;
    }
    return -1;
  }

  @override
  void init() {}

  @override
  void dispose() {}

  /// Attempts to restore Router UI state on startup.
  void inflate() {
//    try {
//      (state.stack ?? BuiltList<String>())
//          .map((n) {
//            final a = store.nestedOfName(n);
//            if (a == null) throw 'RouteActions do not exist $n';
//            if (a is! RouteActions) throw 'Expected RouteActions for $n';
//            return a as RouteActions;
//          })
//          .forEach((r) => _stack.add(r));
//
//      if (_stack.isEmpty) return;
//
//      _stack.forEach((v) => _plugin?.doPush(NavPushPayload(
//          v.actions, v.actions.$mapState(store.state) ?? v.actions.$initial,
//          inflating: true)));
//    } catch (e) {
//      _stack.clear();
//    }
//
//    store.actions.nav.navStack(BuiltList<String>(_stack.map((v) => v.name)));
  }

  void _push(dynamic route) {
    final index = indexOfPlatform(route);
    if (index != -1) return;
    final r = _byPlatform.remove(route);

    if (r == null) {
      _stack.add(ActiveRoute(route, null, null));
    } else {
      r._pushing();
      _stack.add(r);
    }
  }

  void _replace(dynamic oldRoute, dynamic newRoute) {
    final index = indexOfPlatform(oldRoute);
    final n = _byPlatform.remove(newRoute);
    if (index == -1) {
      _stack.add(n);
      _syncState();
      return;
    }

    final o = _stack[index];
    _byPlatform.remove(oldRoute);
    o.future.complete(CommandResultCode.done);
    _stack[index] = n;
    _syncState();
  }

  void _pop(dynamic platform) {
    // Ensure it's removed from byPlatform map.
    _byPlatform.remove(platform);

    // Find index in stack.
    final index = indexOfPlatform(platform);
    if (index == -1) return;
    if (index == _stack.length - 1) {
      _syncState();
      _stack.removeLast()?._popping();
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
    if (_stack?.where((a) => a.entry != null)?.firstWhere(
            (a) => a.entry.toActions?.$actionsType == toActionsType,
            orElse: () => null) !=
        null) {
      future.cancel('already exists');
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
      future.cancel('createRoute() returned null');
      return;
    }

//    switch (future.routeType) {
//      case RouteType.page:
//        break;
//      case RouteType.dialog:
//        break;
//      case RouteType.bottomSheet:
//        break;
//      case RouteType.fullscreen:
//        break;
//    }

//    if (!future.entry.toActions
//        .$ensureState(store, future.command?.payload?.state)) {
//      future.cancel(
//          'failed to ensureState for RouteActions [${future.entry.toActions.$name}]');
//      return;
//    }

    final route = ActiveRoute(platform, future.entry, future);
    _byPlatform[platform] = route;

    route._pushing();

    switch (future.routeAction) {
      case RouteCommandAction.push:
        _plugin?.push(route);
        break;

      case RouteCommandAction.replace:
        var replaceName = future.command?.payload?.replaceName ?? '';
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

      case RouteCommandAction.popAndPush:
        if (_stack.isNotEmpty) _plugin?.pop(_stack.last, null);
        _plugin?.push(route);
        break;
    }
  }

  void _done(RouteFuture future, CommandResult<RouteResult> result) {
    try {
      if (_stack.isEmpty) return;
      final index = _stack.indexOf(future.active);
      if (index < 0) return;

      _stack[index]?._popping();

      // Sync.
      _plugin?.pop(future.active, result);
    } finally {
      _syncState();
    }
  }

  void _syncState() {
    final next = _stack.map((a) => a.future.dispatcher.$name);
    if (state?.stack != next) {
      actions?.stack(next);
    }
  }
}

///
abstract class RouteActions<
        State extends Built<State, StateBuilder>,
        StateBuilder extends Builder<State, StateBuilder>,
        OUT,
        Actions extends RouteActions<State, StateBuilder, OUT, Actions, Route>,
        Route extends RouteDispatcher<State, StateBuilder, OUT, Actions, Route>>
    extends StatefulActions<State, StateBuilder, Actions> {
  bool get $isDialog => false;

  RouteType get $routeType => RouteType.page;

  ActionDispatcher<Null> get $activated;

  ActionDispatcher<Null> get $deactivated;

  ActionDispatcher<State> get $pushing;

  ActionDispatcher<OUT> get $popping;

  RouteFuture<State, StateBuilder, OUT, Actions, Route> get future =>
      $store.service<RouterService>().activeRouteByType(Actions)?.future;

  Future<String> $canDeactivate() {
    return Future.value('');
  }

  bool $canPop() => true;

  bool $pop(Store store, [OUT result]) {
    final service = store.service<RouterService>();
    final active = service.activeOfType($actionsType);
    if (active == null) return false;

    active.future.complete(CommandResultCode.done,
        response: RouteResult<OUT>((b) => b..value = result));

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

  void $onPop(Store store, State state, OUT result) {}

  void $didActivate(Store store, State state) {}

  void $didDeactivate(Store store, State state) {}
}

@BuiltValueEnum(wireName: 'modux/RouteCommandAction')
class RouteCommandAction extends EnumClass {
  static const RouteCommandAction push = _$wirePush;
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
  RouteCommandAction get action;

  @nullable
  RouteType get routeType;

  @nullable
  String get replaceName;

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
        OUT,
        Actions extends RouteActions<State, StateBuilder, OUT, Actions, D>,
        D extends RouteDispatcher<State, StateBuilder, OUT, Actions, D>>
    extends CommandDispatcher<RouteCommand<State>, RouteResult<OUT>, D> {
  Type get $toActionsType => Actions;

  RouteFuture<State, StateBuilder, OUT, Actions, D> get future =>
      $store.service<RouterService>().routesByName[$name]?.future;

  Command<RouteCommand<State>> create(
      {State state,
      StateBuilder Function(StateBuilder) builder,
      bool inflating = false,
      RouteType routeType,
      RouteCommandAction action,
      String replaceName,
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
      if (!route.toActions.$ensureState($store, state)) {
        throw StateError(
            'Command state [${route.toActions.$name}] cannot be initialized. '
            'Parent state [${route.toActions.$options.parent.name}] is null');
      }
    } catch (e) {
      // Ignore.
    }

    if (state == null) state = route.toActions.$initial;

    final b = RouteCommandBuilder<State>()
      ..name = $options.name
      ..from = $options.parent?.name ?? ''
      ..to = route.toActions.$name
      ..state = state
      ..action = action
      ..replaceName = replaceName
      ..routeType = routeType;

    return (CommandBuilder<RouteCommand<State>>()
          ..id = ''
          ..timeout = timeout != Duration.zero ? timeout.inMilliseconds : 0
          ..payload = b.build())
        .build();
  }

  void call(
      {State state,
      StateBuilder Function(StateBuilder) builder,
      bool inflating = false,
      RouteType routeType,
      RouteCommandAction action,
      String replaceName,
      Duration timeout = Duration.zero}) {
    final command = create(
        state: state,
        builder: builder,
        inflating: inflating,
        routeType: routeType,
        action: action,
        replaceName: replaceName,
        timeout: timeout);
    execute(command);
  }

  @override
  RouteFuture<State, StateBuilder, OUT, Actions, D> newFuture(
      Command<RouteCommand<State>> command) {
    final service = $store.service<RouterService>();
    if (service == null) throw RouteConfigError('RouterService not registered');

    final route = service.routesByName[$name];
    if (route == null)
      throw RouteConfigError('Route named [${$name}] was not registered');

    return RouteFuture(service, route, this as D, command);
  }
}

/// RouteFuture
class RouteFuture<
        State extends Built<State, StateBuilder>,
        StateBuilder extends Builder<State, StateBuilder>,
        OUT,
        Actions extends RouteActions<State, StateBuilder, OUT, Actions, D>,
        D extends RouteDispatcher<State, StateBuilder, OUT, Actions, D>>
    extends CommandFuture<RouteCommand<State>, RouteResult<OUT>, D> {
  final RouterService service;
  final RouteEntry entry;
  ActiveRoute _active;

  ActiveRoute get active => _active;
  dynamic get platform => _active?.platform;

  RouteFuture(this.service, this.entry, D dispatcher,
      Command<RouteCommand<State>> command)
      : super(dispatcher, command);

  RouteType get routeType =>
      command?.payload?.routeType ??
      entry.toActions.$routeType ??
      RouteType.page;

  RouteCommandAction get routeAction =>
      command?.payload?.action ?? RouteCommandAction.push;

  bool get isInflating => command?.payload?.inflating ?? false;

  @override
  void execute() {
    service._execute(this);
  }

  @override
  void done(CommandResult<RouteResult> result) {
    service?._done(this, result);
  }
}
