import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

import 'action.dart';
import 'typedefs.dart';

/// [ReducerBuilder] allows you to build a reducer that handles many different actions
/// with many different payload types, while maintaining type safety.
/// Each [Reducer] added with add<T> must take a state of type State, an Action of type
/// Action<T>, and a builder of type B.
/// Nested reducers can be added with [combineNested]
class ReducerBuilder<State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>> {
  final _map = new Map<String, Reducer<State, StateBuilder, dynamic>>();

  ReducerBuilder();

  /// Registers [reducer] function to the given [actionName]
  void add<Payload>(ActionName<Payload> actionName,
      Reducer<State, StateBuilder, Payload> reducer) {
    _map[actionName.name] = (state, builder, action) {
      reducer(state, builder, action as Action<Payload>);
    };
  }

  void bind<T, I>(
      FieldDispatcher<T> from, FieldDispatcher<I> to, I Function(T) map) {
    add(from, (a, b, Action<T> action) {
      to.replaceMapper?.call(b, map(action.payload));
    });
  }

  void bindList<T, I>(FieldDispatcher<BuiltList<T>> from,
      FieldDispatcher<BuiltList<I>> to, I Function(T) map) {
    add(from, (a, b, Action<BuiltList<T>> action) {
      to.value$ = BuiltList<I>(action.payload.map(map));
    });
  }

  NestedReducerBuilder<State, StateBuilder, NestedState, NestedStateBuilder>
      nested<
                  NestedState extends Built<NestedState, NestedStateBuilder>,
                  NestedStateBuilder extends Builder<NestedState,
                      NestedStateBuilder>>(
              NestedState Function(Built<dynamic, dynamic>) stateMapper,
              NestedStateBuilder Function(Builder<dynamic, dynamic>)
                  builderMapper) =>
          NestedReducerBuilder<State, StateBuilder, NestedState,
              NestedStateBuilder>(this, stateMapper, builderMapper);

  NestedReducerBuilder<State, StateBuilder, NestedState, NestedStateBuilder>
      nest<
                  NestedState extends Built<NestedState, NestedStateBuilder>,
                  NestedStateBuilder extends Builder<NestedState,
                      NestedStateBuilder>,
                  NestedActions extends ModuxActions<NestedState,
                      NestedStateBuilder, NestedActions>>(
              ModuxActions<NestedState, NestedStateBuilder, NestedActions>
                  child) =>
          NestedReducerBuilder<State, StateBuilder, NestedState,
              NestedStateBuilder>(this, child.mapState$, child.mapBuilder$);

  /// [build] returns a reducer function that can be passed to a [Store].
  Reducer<State, StateBuilder, dynamic> build() =>
      (State state, StateBuilder builder, Action<dynamic> action) {
        final reducer = _map[action.name];
        if (reducer != null) reducer(state, builder, action);
      };
}

/// [Mapper] is a function that takes an object and maps it to another object.
/// Used for state and builder mappers passed to [NestedReducerBuilder].
//typedef NestedState Mapper<State, NestedState>(State state);

/// [NestedReducerBuilder] allows you to build a reducer that rebuilds built values
/// nested within your main app state model. For example, consider the following built value
///
/// ```dart
/// abstract class BaseState implements Built<BaseState, BaseStateBuilder> {
///
///  NestedBuiltValue get nestedBuiltValue;
///
///  // Built value constructor
///  BaseState._();
///  factory BaseState() => new _$BaseState._(
///        count: 1,
///        nestedBuiltValue: new NestedBuiltValue(),
///      );
/// }
/// ```
/// A NestedReducerBuilder can be used to map certain actions to reducer
/// functions that only rebuild nestedBuiltValue
///
/// Two mapper functions are required by the constructor to map the state and state builder objects
/// to the nested value and nested builder.
///
/// [stateMapper] maps the state built to the nested built, in this case:
/// ```dart
///   (BaseCounter state) => state.nestedBuiltValue
/// ```
///
/// [builderMapper] maps the state builder to the nested builder, in this case:
/// ```dart
///   (BaseCounterBuilder stateBuilder) => stateBuilder.nestedBuiltValue
/// ```
///
class NestedReducerBuilder<
    State extends Built<State, StateBuilder>,
    StateBuilder extends Builder<State, StateBuilder>,
    NestedState extends Built<NestedState, NestedStateBuilder>,
    NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>> {
  final ReducerBuilder reducerBuilder;
  final NestedState Function(State) stateMapper;
  final NestedStateBuilder Function(StateBuilder) builderMapper;

  NestedReducerBuilder(
      this.reducerBuilder, this.stateMapper, this.builderMapper);

  static NestedReducerBuilder<State, StateBuilder, NestedState,
      NestedStateBuilder> of<
          State extends Built<State, StateBuilder>,
          StateBuilder extends Builder<State, StateBuilder>,
          NestedState extends Built<NestedState, NestedStateBuilder>,
          NestedStateBuilder extends Builder<NestedState, NestedStateBuilder>>(
      ReducerBuilder reducerBuilder,
      NestedState Function(Built<dynamic, dynamic>) stateMapper,
      NestedStateBuilder Function(Builder<dynamic, dynamic>) builderMapper) {
    return NestedReducerBuilder<State, StateBuilder, NestedState,
        NestedStateBuilder>(reducerBuilder, stateMapper, builderMapper);
  }

  /// Registers [reducer] function to the given [actionName]
  void add<Payload>(ActionName<Payload> actionName,
      Reducer<NestedState, NestedStateBuilder, Payload> reducer) {
    reducerBuilder.add(
        actionName,
        (state, builder, action) => reducer(
              stateMapper(state),
              builderMapper(builder),
              action as Action<Payload>,
            ));
  }

  /// Registers [reducer] function to the given [actionName]
  void map<Payload>(
      ActionName<Payload> actionName,
      NestedReducer<State, StateBuilder, NestedState, NestedStateBuilder,
              Payload>
          reducer) {
    reducerBuilder.add(
        actionName,
        (state, builder, action) => reducer(
              state,
              builder,
              stateMapper(state),
              builderMapper(builder),
              action as Action<Payload>,
            ));
  }
}
