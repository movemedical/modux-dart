import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'dart:collection';

import 'action.dart';
import 'command.dart';
import 'middleware.dart';
import 'reducer.dart';
import 'store.dart';

part 'router.g.dart';

abstract class RouterPlugin<R> {
  R createRoute(RouteFuture future);

  Future processPush(RouteFuture future) async {}

  Future processPop(RouteFuture future, RouteResult result) async {}

  Future replace(RouteFuture future, R oldRoute, R newRoute) async {}
}

typedef PlatformRouteBuilder = Function(RouteFuture);

class ActiveRoute {
  dynamic platform;
  RouteFuture future;
}

class RouteEntry {
  final String key;
  final Store store;
  final RouteDispatcher dispatcher;
  final ModuxActions fromActions;
  final RouteActions toActions;

  RouteFuture _future;

  RouteFuture get future => _future;

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

///
class RouterService implements StoreService, RouterRegistry {
  final Store store;

  final _stack = List<RouteEntry>();
  final _activeByToType = LinkedHashMap<Type, RouteEntry>();

  final HasRouterActions actions;
  RouterRegistry _registry;

  RouterRegistry get registry => _registry;

  RouterPlugin _plugin;

  RouterService(this.store, this.actions, {RouterRegistry registry})
      : _registry = registry {
    if (_registry == null) {
      _registry = ReflectiveRouterRegistry(store);
    }
  }

  void install(RouterPlugin plugin) {
    if (_plugin != null)
      throw StateError('RouterPlugin [$_plugin] was already installed');

    _plugin = plugin;
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

  HasRouterState get state => actions.$mapState(store.state);

  @override
  void init() {}

  @override
  void dispose() {}

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

  /// Given a Platform Route object, find an associated active RouteFuture.
  RouteFuture byPlatformRoute(dynamic route) {
    // Search the stack.
    return _stack.firstWhere((r) => r.future?.platform == route)?.future;
  }

  void _execute(RouteFuture future) {
    final toActionsType = future.dispatcher.$toActionsType;

    // Ensure Route isn't already in the stack.
    for (final entry in _stack) {
      if (entry.toActions.$actionsType == toActionsType) {
        future.cancel('already exists');
        return;
      }
    }

    var active = _activeByToType[future.dispatcher.$toActionsType];
    if (active != null && active.future != null) {
      active.future.cancel('new request');
      _activeByToType.remove(future.dispatcher.$toActionsType);
    }

    future.platform = _plugin?.createRoute(future);

    // Add to stack.
    if (future.isReplace) {}

    // Create Platform Route.
  }

  void _done(RouteFuture future) {
    try {
      if (_stack.isEmpty) return;

      // Last Route?
      if (_stack.last != future.route) {
        // Is it in the stack at all?
        if (!_stack.contains(future.route)) {
          return;
        }

        // Pop them in correct order.
        final index = _stack.indexOf(future.route);
        for (int i = _stack.length - 1; i >= index; i--) {
          final next = _stack.removeLast();
          _activeByToType.remove(next.toActions.$actionsType);
        }
      }

      if (!_stack.remove(future.route)) {}
    } finally {
      _syncState();
    }
  }

  void _syncState() {
    final newStack = BuiltList<String>(_stack.map((r) => r.key).toList());
    if (state.stack == null || state.stack != newStack) actions.stack(newStack);
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

  ActionDispatcher<dynamic> get $activatedAction;

  ActionDispatcher<dynamic> get $deactivatedAction;

  ActionDispatcher<dynamic> get $pushAction;

  ActionDispatcher<dynamic> get $popAction;

  RouteFuture<State, StateBuilder, OUT, Actions, Route> get future =>
      $store.service<RouterService>()._activeByToType[Actions]?.future;

  Future<String> $canDeactivate() {
    return Future.value('');
  }

  bool $canPop() => true;

  @override
  void $reducer(ReducerBuilder reducer) {
    super.$reducer(reducer);

    reducer.nest(this);
  }

  @override
  void $middleware(MiddlewareBuilder builder) {
    super.$middleware(builder);

    builder.nest(this)
      ..add($activatedAction, (api, next, action) {})
      ..add($deactivatedAction, (api, next, action) {})
      ..add($pushAction, (api, next, action) {
        final service = api.store.service<RouterService>();
//        $onRoutePush(api.store, api.state, action.payload);
      })
      ..add($popAction, (api, next, action) {
        final service = api.store.service<RouterService>();
//        $onRoutePop(api.store, api.state, action.payload);
      });
  }
}

@BuiltValue(wireName: 'modux/RouteProps')
abstract class RouteProps implements Built<RouteProps, RoutePropsBuilder> {
  bool get inflating;

  bool get replaceRoute;

  bool get fullscreen;

  RouteProps._();

  factory RouteProps([void updates(RoutePropsBuilder b)]) = _$RouteProps;

  static Serializer<RouteProps> get serializer => _$routePropsSerializer;
}

///
@BuiltValue(wireName: 'modux/RouteCommand')
abstract class RouteCommand<T>
    implements Built<RouteCommand<T>, RouteCommandBuilder<T>> {
  String get name;

  String get from;

  String get to;

  T get state;

  RouteProps get props;

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
  RouteProps createProps(Actions actions) {
    return RouteProps((b) => b
      ..inflating = false
      ..fullscreen = actions.$isDialog
      ..replaceRoute = false);
  }

  Type get $toActionsType => Actions;

  RouteFuture<State, StateBuilder, OUT, Actions, D> get future =>
      $store.service<RouterService>().routesByName[$name]?.future;

  Command<RouteCommand<State>> create(
      {State state,
      bool inflating = false,
      bool replaceRoute = false,
      bool fullscreen = false,
      Duration timeout = Duration.zero}) {
    final service = $store.service<RouterService>();
    if (service == null) throw RouteConfigError('RouterService not registered');

    final route = service.routesByName[$name];
    if (route == null)
      throw RouteConfigError('Route named [${$name}] was not registered');

    if (state == null) state = route.toActions.$initial;

    final b = RouteCommandBuilder<State>()
      ..name = $options.name
      ..from = $options.parent?.name ?? ''
      ..to = route.toActions.$name
      ..state = state
      ..props = (RoutePropsBuilder()
        ..inflating = inflating
        ..fullscreen = fullscreen
        ..replaceRoute = replaceRoute);

    return (CommandBuilder<RouteCommand<State>>()
          ..id = ''
          ..timeout = timeout != Duration.zero ? timeout.inMilliseconds : 0
          ..payload = b.build())
        .build();
  }

  void call(
      {State state,
      bool inflating = false,
      bool replaceRoute = false,
      bool fullscreen = false,
      Duration timeout = Duration.zero}) {
    final command = create(
        state: state,
        inflating: inflating,
        replaceRoute: replaceRoute,
        fullscreen: fullscreen,
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
  final RouteEntry route;
  dynamic platform;
  Future platformFuture;

  RouteFuture(this.service, this.route, D dispatcher,
      Command<RouteCommand<State>> command)
      : super(dispatcher, command);

  bool get isReplace => command?.payload?.props?.replaceRoute ?? false;

  bool get isFullScreen => command?.payload?.props?.fullscreen ?? false;

  bool get isInflating => command?.payload?.props?.inflating ?? false;

  @override
  void execute() {
    service._execute(this);
  }

  @override
  void done(CommandResult<RouteResult> result) {
    service?._done(this);
  }
}
