import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';

import 'command.dart';
import 'middleware.dart';
import 'reducer.dart';
import 'store.dart';
import 'typedefs.dart';

part 'action.g.dart';

abstract class ModuxValue<T> {
  String get name$;

  Store get store$;

  T mapValue$(Store store);

  T get value$;

  set value$(T value);

  ActionDispatcher<T> get replace$;

  StoreSubscription<T> onReplace$([Function(T) handler]);
}

class ActionModel {
  final List<Type> types;

  const ActionModel(this.types);
}

/// [Action] is the object passed to your reducer to signify the state change
/// that needs to take place. Action [name]s should always be unique.
/// Uniqueness is guaranteed when using ModuxActions.
@immutable
class Action<Payload> {
  Action(this.name, this.payload, this.dispatcher);

  /// A unique action name.
  final String name;

  /// The actions payload.
  final Payload payload;

  /// [ActionDispatcher] that dispatched this Action.
  final ActionDispatcher<Payload> dispatcher;

  ModuxActions get parent => dispatcher?.parent?.actions;

  @override
  String toString() => 'Action {\n  name: $name,\n  payload: $payload\n}';
}

/// Dispatches an action to the store.
typedef void Dispatcher<P>(Action<P> action);

///
class StoreProxy {
  Store store;
  Dispatcher dispatcher;

  void dispatch<P>(Action<P> action) {
    dispatcher?.call(action);
  }
}

/// [ActionDispatcher] dispatches an action with the name provided
/// to the constructor and the payload supplied when called. You will notice
/// [ActionDispatcher] is an object, however it is to be used like a function.
/// In the following example increment is an action dispatcher, that when called
/// dispatches an action to the redux store with the name increment and the payload 3.
///
/// ```dart
/// store.actions.increment(3);
/// ```
@immutable
class ActionDispatcher<P> extends ActionName<P> {
  final StatefulActionsOptions parent;
  final Dispatcher _dispatcher;
  final ActionDispatcher<P> Function(ModuxActions) localMapper;
  final ActionDispatcher<P> Function(ModuxActions) mapper;

  ActionDispatcher(String simpleName, String name, this.parent,
      this.localMapper, this.mapper)
      : _dispatcher = parent.store.dispatch,
        super(simpleName, name);

  Store get store => parent.store.store;

  void call([P payload]) => _dispatcher(Action<P>(name, payload, this));

  bool isDescendentOf(ModuxActions actions) => name.startsWith(actions.name$);

  int ancestorCount(ModuxActions actions) {
    if (!isDescendentOf(actions)) return -1;
    var n = name.substring(actions.name$.length);
    if (n.startsWith('-'))
      return 0;
    else
      return _countChars(n, '.');
  }

  StoreSubscription<P> listen([Function(P) handler]) =>
      store?.listen(this, handler);

  StoreSubscription<P> subscribe() => store?.subscribe(this);
}

///
int _countChars(String str, String c) {
  var count = 0;

  for (int i = 0; i < str.length; i++) {
    if (str[i] == c) {
      count++;
    }

    return count;
  }
}

///
@immutable
class FieldDispatcher<State> extends ActionDispatcher<State>
    implements ModuxValue<State> {
  final State Function(Built) localStateMapper;
  final State Function(Built) stateMapper;
  final Function(Builder, State) replaceMapper;

  FieldDispatcher(
    String simpleName,
    String name,
    StatefulActionsOptions parent,
    ActionDispatcher<State> Function(ModuxActions) localMapper,
    ActionDispatcher<State> Function(ModuxActions) mapper,
    this.localStateMapper,
    this.stateMapper,
    this.replaceMapper,
  ) : super(simpleName, name, parent, localMapper, mapper);

  void reducer$(ReducerBuilder reducer) {
    reducer.add(
        this,
        (state, builder, action) =>
            replaceMapper?.call(builder, action.payload));
  }

  @override
  String get name$ => name;

  @override
  State get value$ => mapValue$(store);

  @override
  set value$(State value) => this(value);

  @override
  State mapValue$(Store store) => stateMapper(store.state);

  @override
  ActionDispatcher<State> get replace$ => this;

  @override
  StoreSubscription<State> onReplace$([Function(State) handler]) =>
      store$?.listen(this, handler);

  @override
  Store get store$ => store;
}

/// [ModuxActions] is a container for all of your applications actions.
///
/// When using [ModuxActions] the developer does not have to instantiate
/// their [ActionDispatcher]s, they only need to define them.
///
/// The generator will generate a class with all of the boilerplate need to
/// instantiate the [ActionDispatcher]s and sync them with the redux action
/// dispatcher.
///
/// The generator will also generate another class, [ActionNames], that
/// contains a static accessors for each [ActionDispatcher] that is typed with
/// a generic that is the same as the [ActionDispatcher] payload generic. This
/// allows you to build reducer handlers with type safety without having to
/// instantiate your instance of [ModuxActions].
///
/// One can also nest [ModuxActions] just like one can nest built_values.
///
///  Example:
///
///  The following actions
///
///  ```dart
///  abstract class BaseActions extends ReduxActions
///       <MyState, MyStateBuilder, BaseActions> {
///   ActionDispatcher<int> get foo;
///   NestedActions get nested;
///
///   BaseActions._();
///   factory BaseActions(BaseActionsOptions options) = _$BaseActions;
///  }
///
///  abstract class NestedActions extends ReduxActions
///       <NestedState, NestedStateBuilder, NestedActions> {
///   ActionDispatcher<int> get bar;
///
///   NestedActions._();
///   factory NestedActions(NestedActionsOptions options) = _$NestedActions;
///  }
///  ```
///
///  generate to
///
///  ```dart
///  typedef ReduxActionsOptions<MyState, MyStateBuilder,
///      BaseActions> BaseActionsOptions()
///
///  class _$BaseActions extends BaseActions {
///    final ReduxActionsOptions<MyState, MyStateBuilder, BaseActions> options;
///    final ActionDispatcher<int> foo;
///    final NestedActions nestedActions;
///
///    _$BaseActions._(this.options) :
///       foo = options.action<int>('foo', (a) => a?.foo),
///       nestedActions = NestedActions(
///             options.stateful
///               <NestedState, NestedStateBuilder, NestedActions>(
///                 'nested',
///                 (a) => a.nested
///                 (s) => s?.nested,
///                 (b) => b?.nested,
///                 (p, b) => p?.nested = b,
///               )
///           ),
///       super();
///
///    @override
///    void reducer$(ReducerBuilder reducer) {
///      super.reducer$(reducer);
///    }
///  }
/// ```
abstract class ModuxActions<
    LocalState extends Built<LocalState, LocalStateBuilder>,
    LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
    LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
        LocalActions>> {
  static final _emptyNested = BuiltList<ModuxActions>();
  static final _emptyActions = BuiltList<ActionDispatcher>();

  StatefulActionsOptions<LocalState, LocalStateBuilder, LocalActions>
      get options$;

  String get name$ => options$.name;

  String get simpleName$ => options$.simpleName;

  LocalState get initialState$;

  LocalStateBuilder get initialBuilder$ =>
      initialState$?.toBuilder() ?? newBuilder$();

  Type get stateType$ => LocalState;

  Type get builderType$ => LocalStateBuilder;

  Type get actionsType$ => LocalActions;

  Store get store$ => options$.store.store;

  BuiltList<ModuxActions> get nested$ => _emptyNested;
  BuiltMap<String, ModuxActions> _$nestedMap;

  BuiltMap<String, ModuxActions> get nestedMap$ =>
      _$nestedMap ??= BuiltMap<String, ModuxActions>.build(
          (b) => nested$.forEach((n) => b[n.simpleName$] = n));

  BuiltList<ActionDispatcher> get actions$ => _emptyActions;
  BuiltMap<String, ActionDispatcher> _$actionsMap;

  BuiltMap<String, ActionDispatcher> get $actionsMap =>
      _$actionsMap ??= BuiltMap<String, ActionDispatcher>.build(
          (b) => actions$.forEach((a) => b[a.simpleName] = a));

  void visitCommands$(void fn(ModuxActions owner, CommandDispatcher a)) {
    visitNested$((actions) {
      if (actions is CommandDispatcher)
        fn(actions.mapParent$(store$.actions), actions);
    });
  }

  void visitNested$(Function(ModuxActions a) callback) {
    nested$?.forEach((actions) {
      actions.visitNested$(callback);
      callback(actions);
    });
  }

  ModuxActions nestedByRelativeName$(String name) {
    var index = name.lastIndexOf('-');
    if (index == 0) return null;

    // Clean action name if necessary.
    if (index > -1) {
      name = name.substring(0, index);
    }

    index = name.indexOf('.');
    if (index > -1) {
      final nested = nestedMap$[name.substring(0, index)];
      if (nested == null) return null;

      if (index == name.length - 1) {
        return null;
      }

      return nested.nestedByRelativeName$(name.substring(index + 1));
    } else {
      return nestedMap$[name];
    }
  }

  LocalStateBuilder newBuilder$();

  bool get isStateful$ => true;

  bool get isStateless$ => false;

  bool get isSerializable$ => serializer$ != null;

  LocalState get state$ => mapState$(store$.state);

  LocalStateBuilder get builder$ => initialBuilder$;

  LocalStateBuilder toBuilder$() => state$.toBuilder();

  LocalStateBuilder build$(void updates(LocalStateBuilder b)) {
    final builder = builder$;
    updates?.call(builder);
    return builder;
  }

  StoreSubject listen$<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              Actions extends ModuxActions<State, StateBuilder, Actions>>(
          Store<State, StateBuilder, Actions> store,
          [Function(ActionEvent) handler]) =>
      store.nestedStream(this, handler);

  bool isAncestor$<T>(Action<T> event) =>
      event.name.startsWith(name$) || name$.startsWith(event.name);

  bool isParent$<T>(Action<T> event) => name$.startsWith(event.name);

  bool isChild$<T>(Action<T> event) => event.name.startsWith(name$);

  LocalState mapState$(Built<dynamic, dynamic> appState) =>
      options$.stateMapper(appState);

  LocalStateBuilder mapBuilder$(Builder<dynamic, dynamic> appBuilder) =>
      options$.builderMapper(appBuilder);

  void reduceReplace$(
          Builder<dynamic, dynamic> appBuilder, LocalStateBuilder builder) =>
      options$.builderSetter(appBuilder, builder);

  /// Map Parent.
  ModuxActions mapParent$(ModuxActions appActions) =>
      options$.parentMapper(appActions);

  ModuxActions get parent$ => mapParent$(store$.actions);

  Built get parentState$ => parent$.state$;

  /// Map Self.
  LocalActions mapActions$(ModuxActions appActions) =>
      options$.mapper(appActions);

  Serializer get serializer$ => null;

  Reducer<LocalState, LocalStateBuilder, dynamic> createReducer$() {
    final reducer = ReducerBuilder<LocalState, LocalStateBuilder>();
    reducer$(reducer);
    return reducer.build();
  }

  @mustCallSuper
  void reducer$(ReducerBuilder reducer) {}

  Middleware<LocalState, LocalStateBuilder, LocalActions> createMiddleware$() {
    final middleware =
        MiddlewareBuilder<LocalState, LocalStateBuilder, LocalActions>();
    middleware$(middleware);
    return middleware.build();
  }

  @mustCallSuper
  void middleware$(MiddlewareBuilder builder) {}
}

abstract class StatefulActions<
        LocalState extends Built<LocalState, LocalStateBuilder>,
        LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
        LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
            LocalActions>>
    extends ModuxActions<LocalState, LocalStateBuilder, LocalActions>
    implements ModuxValue<LocalState> {
  @override
  ActionDispatcher<LocalState> get replace$;

  @override
  LocalState get value$ => mapValue$(store$);

  @override
  set value$(LocalState value) => reset$(value);

  @override
  LocalState mapValue$(Store store) => mapState$(store.state);

  @override
  StoreSubscription<LocalState> onReplace$([Function(LocalState) handler]) =>
      replace$.listen(handler);

  @override
  bool get isStateful$ => true;

  void reset$([LocalState state]) {
    replace$(state ?? initialState$);
  }

  @mustCallSuper
  void reducer$(ReducerBuilder reducer) {
    super.reducer$(reducer);
    reducer.nest(this)
      ..map(replace$,
          (appState, appBuilder, state, builder, Action<LocalState> action) {
        reduceReplace$(appBuilder, action.payload.toBuilder());
      });
  }

  @mustCallSuper
  void middleware$(MiddlewareBuilder middleware) {
    super.middleware$(middleware);
    middleware.nest(this)..add(replace$, didReplace$);
  }

  void didReplace$(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, LocalState,
              LocalStateBuilder, LocalActions>
          api,
      ActionHandler next,
      Action<LocalState> action) {}

  /// Ensures the parent state hierarchy is initialized. If not it attempts
  /// to initialize as far up as needed. This automatically builds all
  /// parent state so this LocalState may exist in the State Graph.
  bool ensureState$([LocalState state]) {
    final store = store$;
    dynamic current = mapState$(store.state);
    if (current != null) {
      if (this is StatefulActions && state != null) {
        reset$(state);
      }
      return true;
    }

    var parent = mapParent$(store.actions);
    if (parent == null) {
      if (parent is StatefulActions) {
        parent.reset$();
      }
      if (this is StatefulActions) {
        reset$(state);
      }
      return true;
    }
    var parentState = parent.mapState$(store.state);
    if (parentState == null) {
      (parent as StatefulActions).ensureState$();
    }

    parentState = parent.mapState$(store.state);
    if (parentState == null) return false;

    reset$(state);
    return mapState$(store.state) != null;
  }
}

@immutable
class StatefulActionsOptions<
    LocalState extends Built<LocalState, LocalStateBuilder>,
    LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
    LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
        LocalActions>> {
  final StatefulActionsOptions parent;
  final String name;
  final String simpleName;
  final StoreProxy store;
  final LocalActions Function(ModuxActions) mapper;
  final ModuxActions Function(ModuxActions) parentMapper;
  final LocalState Function(Built<dynamic, dynamic>) stateMapper;
  final LocalStateBuilder Function(Builder<dynamic, dynamic>) builderMapper;
  final Function(Builder, LocalStateBuilder) builderSetter;

  StatefulActionsOptions(
      this.parent,
      this.name,
      this.simpleName,
      this.store,
      this.parentMapper,
      this.mapper,
      this.stateMapper,
      this.builderMapper,
      this.builderSetter);

  LocalActions get actions => mapper?.call(store?.store?.actions);

  ActionDispatcher<P> action<P>(
      String simpleName, ActionDispatcher<P> mapper(ReduxActions)) {
    final name = this.name == '' ? '-$simpleName' : '${this.name}-$simpleName';
    return ActionDispatcher<P>(
        simpleName, name, this, mapper, (a) => mapper(this.mapper(a)));
  }

  FieldDispatcher<P> field<P>(
      String simpleName,
      FieldDispatcher<P> mapper(LocalActions),
      P localStateMapper(LocalState),
      void replace(LocalStateBuilder, P)) {
    final name = this.name == '' ? '-$simpleName' : '${this.name}-$simpleName';
    return FieldDispatcher<P>(
        simpleName,
        name,
        this,
        mapper,
        (a) => mapper(this.mapper(a)),
        (s) => localStateMapper(s),
        (s) => localStateMapper(this.stateMapper(s)), (app, b) {
      final replaceBuilder = this.builderMapper(app);
      if (b != null && b is Built)
        replace?.call(replaceBuilder, b.toBuilder());
      else if (b is BuiltList)
        replace?.call(replaceBuilder, b.toBuilder());
      else if (b is BuiltMap)
        replace?.call(replaceBuilder, b.toBuilder());
      else if (b is BuiltSet)
        replace?.call(replaceBuilder, b.toBuilder());
      else if (b is BuiltListMultimap)
        replace?.call(replaceBuilder, b.toBuilder());
      else if (b is BuiltSetMultimap)
        replace?.call(replaceBuilder, b.toBuilder());
      else
        replace?.call(replaceBuilder, b);
    });
  }

  StatelessActionsOptions<A> stateless<A extends StatelessActions<A>>(
      String simpleName, A Function(LocalActions) mapper) {
    final name = this.name == '' ? simpleName : '${this.name}.$simpleName';
    return StatelessActionsOptions<A>(this, name, simpleName, store,
        this.mapper, (a) => mapper(this.mapper(a)));
  }

  StatefulActionsOptions<ChildState, ChildStateBuilder, ChildActions> stateful<
          ChildState extends Built<ChildState, ChildStateBuilder>,
          ChildStateBuilder extends Builder<ChildState, ChildStateBuilder>,
          ChildActions extends ModuxActions<ChildState, ChildStateBuilder,
              ChildActions>>(
      String simpleName,
      ChildActions mapper(LocalActions),
      ChildState childStateMapper(LocalState),
      ChildStateBuilder childBuilderMapper(LocalStateBuilder),
      void childReplace(LocalStateBuilder, ChildStateBuilder)) {
    final name = this.name == '' ? simpleName : '${this.name}.$simpleName';
    return StatefulActionsOptions<ChildState, ChildStateBuilder, ChildActions>(
        this,
        name,
        simpleName,
        store,
        this.mapper,
        (a) => mapper?.call(this.mapper?.call(a)) ?? null,
        (s) => childStateMapper?.call(this.stateMapper?.call(s)) ?? null,
        (b) =>
            childBuilderMapper?.call(this.builderMapper?.call(b) ?? null) ??
            null, (appBuilder, childBuilder) {
      final parentBuilder = this.builderMapper(appBuilder);
      if (parentBuilder != null) {
        childReplace(parentBuilder, childBuilder);
      }
    });
  }

  static StatefulActionsOptions<State, StateBuilder, Actions> root<
      State extends Built<State, StateBuilder>,
      StateBuilder extends Builder<State, StateBuilder>,
      Actions extends ModuxActions<State, StateBuilder, Actions>>() {
    return StatefulActionsOptions(null, '', '', StoreProxy(), null, (a) => a,
        (s) => s, (b) => b, (p, b) => p?.replace(b.build()));
  }
}

///
abstract class ModelActions<
        LocalState extends Built<LocalState, LocalStateBuilder>,
        LocalStateBuilder extends Builder<LocalState, LocalStateBuilder>,
        LocalActions extends ModuxActions<LocalState, LocalStateBuilder,
            LocalActions>>
    extends StatefulActions<LocalState, LocalStateBuilder, LocalActions> {}

abstract class Nothing implements Built<Nothing, NothingBuilder> {
  Nothing._();

  factory Nothing([updates(NothingBuilder b)]) = _$Nothing;

  static Serializer<Nothing> get serializer => _$nothingSerializer;
}

abstract class Value<T> implements Built<Value<T>, ValueBuilder<T>> {
  T get value;

  Value._();

  factory Value([updates(ValueBuilder<T> b)]) = _$Value<T>;

  static Serializer<Value> get serializer => _$valueSerializer;
}

@immutable
class StatelessActionsOptions<
        Actions extends ModuxActions<Nothing, NothingBuilder, Actions>>
    extends StatefulActionsOptions<Nothing, NothingBuilder, Actions> {
  StatelessActionsOptions(
      StatefulActionsOptions parent,
      String name,
      String simpleName,
      StoreProxy dispatcher,
      ModuxActions Function(ModuxActions) parentMapper,
      Actions Function(ModuxActions) mapper)
      : super(parent, name, simpleName, dispatcher, parentMapper, mapper,
            (s) => Nothing(), (b) => NothingBuilder(), (parent, builder) {});
}

///
abstract class StatelessActions<Actions extends StatelessActions<Actions>>
    extends ModuxActions<Nothing, NothingBuilder, Actions> {
  @override
  Nothing get initialState$ => Nothing();

  @override
  NothingBuilder newBuilder$() => NothingBuilder();

  @override
  bool get isStateful$ => false;

  @override
  bool get isStateless$ => true;

  @override
  Nothing get state$ => Nothing();
}

/// [ActionName] is an object that simply contains the action name but is
/// typed with a generic that is the same as the relative [ActionDispatcher]s
/// payload generic. This allows you to declare reducer handlers with safety
/// without having to instantiate your instance of [ModuxActions].
@immutable
class ActionName<T> {
  final String simpleName;
  final String name;

  ActionName(this.simpleName, this.name);
}
