import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

import 'action.dart';
import 'store.dart';
import 'typedefs.dart';

/// [MiddlewareApi] put in scope to your [Middleware] function by redux.
/// When using [MiddlewareBuilder] (recommended) [MiddlewareApi] is passed to your [MiddlewareHandler]
class MiddlewareApi<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>> {
  final Store<State, StateBuilder, Actions> store;
  final State state;
  final Actions actions;

  MiddlewareApi._(this.store, this.state, this.actions);

  factory MiddlewareApi(Store<State, StateBuilder, Actions> _store) =>
      MiddlewareApi._(_store, _store.state, _store.actions);
}

/// [MiddlewareApi] put in scope to your [Middleware] function by redux.
/// When using [MiddlewareBuilder] (recommended) [MiddlewareApi] is passed to your [MiddlewareHandler]
class NestedMiddlewareApi<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>,
    NestedActions extends ModuxActions<NestedState, NestedStateBuilder,
        NestedActions>> {
  final Store<State, StateBuilder, Actions> store;
  final NestedState state;
  final NestedActions actions;

  NestedMiddlewareApi._(this.store, this.state, this.actions);
}

/// [MiddlewareBuilder] allows you to build a reducer that handles many different actions
/// with many different payload types, while maintaining type safety.
/// Each [MiddlewareHandler] added with add<T> must take a state of type State, an Action of type
/// Action<T>, and a builder of type StateBuilder
class MiddlewareBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>> {
  var _map = ListMultimapBuilder<String,
      MiddlewareHandler<State, StateBuilder, Actions, dynamic>>();

  BuiltListMultimap<String,
      MiddlewareHandler<State, StateBuilder, Actions, dynamic>> _mapBuilt;
  BuiltListMultimap<String,
          MiddlewareHandler<State, StateBuilder, Actions, dynamic>>
      get map => _mapBuilt ??= _map.build();

//  var _map = new Map<String,
//      MiddlewareHandler<State, StateBuilder, Actions, dynamic>>();

  void add<Payload>(ActionName<Payload> aMgr,
      MiddlewareHandler<State, StateBuilder, Actions, Payload> handler) {
    _map.add(aMgr.name, (api, next, action) {
      handler(api, next, action as Action<Payload>);
    });
  }

  NestedMiddlewareBuilder<State, StateBuilder, Actions, NestedState,
          NestedStateBuilder, NestedActions>
      nest<
                  NestedState extends Built<NestedState, NestedStateBuilder>,
                  NestedStateBuilder extends Builder<NestedState,
                      NestedStateBuilder>,
                  NestedActions extends ModuxActions<NestedState,
                      NestedStateBuilder, NestedActions>>(
              ModuxActions<NestedState, NestedStateBuilder, NestedActions>
                  actions) =>
          NestedMiddlewareBuilder(this, actions.$mapState, actions.$mapActions);

  NestedMiddlewareBuilder<State, StateBuilder, Actions, NestedState,
          NestedStateBuilder, NestedActions>
      nested<
                  NestedState extends Built<NestedState, NestedStateBuilder>,
                  NestedStateBuilder extends Builder<NestedState,
                      NestedStateBuilder>,
                  NestedActions extends ModuxActions<NestedState,
                      NestedStateBuilder, NestedActions>>(
              NestedState Function(State) stateMapper,
              NestedStateBuilder Function(State) builderMapper,
              NestedActions Function(Actions) actionsMapper) =>
          NestedMiddlewareBuilder(this, stateMapper, actionsMapper);

  /// [build] returns a [Middleware] function that handles all actions added with [add]
  Middleware<State, StateBuilder, Actions> build() =>
      (MiddlewareApi<State, StateBuilder, Actions> api) =>
          (ActionHandler next) => (Action<dynamic> action) {
                next(action);

                map[action.name]
                    ?.forEach((handler) => handler?.call(api, next, action));
//                if (handlers != null) {
//                  for (final h in handlers) {
//                    h(api, next, action);
//                  }
//                  return;
//                }
              };
}

class NestedMiddlewareBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>,
    NestedActions extends ModuxActions<NestedState, NestedStateBuilder,
        NestedActions>> {
  final MiddlewareBuilder middlewareBuilder;
  final NestedState Function(State) _stateMapper;
  final NestedActions Function(Actions) _actionsMapper;

  NestedMiddlewareBuilder(
      this.middlewareBuilder, this._stateMapper, this._actionsMapper);

  void add<Payload>(
      ActionName<Payload> aMgr,
      NestedMiddlewareHandler<State, StateBuilder, Actions, NestedState,
              NestedStateBuilder, NestedActions, Payload>
          handler) {
    middlewareBuilder.add(aMgr, (api, next, action) {
      handler(
          NestedMiddlewareApi._(api.store, _stateMapper(api.store.state),
              _actionsMapper(api.store.actions)),
          next,
          action as Action<Payload>);
    });
  }
}

/// [MiddlewareHandler] is a function that handles an action in a middleware. Its is only for
/// use with [MiddlewareBuilder]. If you are not using [MiddlewareBuilder] middleware must be
/// declared as a [Middleware] function.
typedef void MiddlewareHandler<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>,
    Payload>(MiddlewareApi<State, StateBuilder, Actions> api, ActionHandler next, Action<Payload> action);

typedef void NestedMiddlewareHandler<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder, Actions>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>,
    NestedActions extends ModuxActions<NestedState, NestedStateBuilder,
        NestedActions>,
    Payload>(NestedMiddlewareApi<State, StateBuilder, Actions, NestedState, NestedStateBuilder, NestedActions> api, ActionHandler next, Action<Payload> action);
