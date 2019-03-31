import 'package:built_value/built_value.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart' as ws;

import 'action.dart';
import 'middleware.dart';
import 'store_change.dart';

typedef HttpClientFactory = http.Client Function();
typedef WebSocketFactory = ws.WebSocketChannel Function(dynamic url,
    {Iterable<String> protocols,
    Map<String, dynamic> headers,
    Duration pingInterval});

/// [Reducer] is a function that given a state of type V, an Action of type Action<P>, and a
/// builder of type B builds the next state
typedef void Reducer<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Payload>(State state, StateBuilder builder, Action<Payload> action);

typedef void NestedReducer<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>,
    Payload>(State appState, StateBuilder appBuilder, NestedState state, NestedStateBuilder builder, Action<Payload> action);

/// [ActionHandler] handles an action, this will contain the actual middleware logic
typedef void ActionHandler(Action<dynamic> a);

/// [NextActionHandler] takes the next [ActionHandler] in the middleware chain and returns
/// an [ActionHandler] for the middleware
typedef ActionHandler NextActionHandler(ActionHandler next);

/// [Middleware] is a function that given the store's [MiddlewareApi] returns a [NextActionHandler].
typedef NextActionHandler Middleware<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    Actions extends ModuxActions<State, StateBuilder,
        Actions>>(MiddlewareApi<State, StateBuilder, Actions> api);

/// [SubStateChange] is the payload for `StateChangeTransformer`'s stream. It contains
/// the previous and next value of the state resulting from the mapper provided to `StateChangeTransformer`
class SubStateChange<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, SubState, P> {
  final SubState prev;
  final SubState next;
  final StoreChange<State, StateBuilder, P> change;

  bool get didChange => prev != next;

  SubStateChange(this.prev, this.next, this.change);
}

/// [StateMapper] takes a state model and maps it to the values one cares about
typedef SubState StateMapper<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>, SubState>(State state);
