import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';

import 'action.dart';
import 'middleware.dart';
import 'reducer.dart';
import 'store.dart';
import 'typedefs.dart';

part 'command.g.dart';

final uuid = new IdGenerator();

class IdGenerator {
  final now = DateTime.now();
  final String prefix = '${DateTime.now().millisecondsSinceEpoch.toString()}-';
  var _count = 0;

  String next() => '$prefix${_count++}';
}

abstract class StandardCommandDispatcher<REQ, RESP,
        D extends CommandDispatcher<REQ, RESP, D>>
    extends CommandDispatcher<REQ, RESP, D> {
  void call(REQ request, {String id = '', int timeout = 15000}) =>
      $execute((CommandPayloadBuilder<REQ, RESP, D, Command<REQ>>()
            ..detached = false
            ..dispatcher = this as D
            ..payload = Command<REQ>((b) => b
              ..id = id == null || id.isEmpty ? uuid.next() : id
              ..payload = request
              ..timeout = timeout))
          .build());
}

///
abstract class CommandDispatcher<REQ, RESP,
        Actions extends CommandDispatcher<REQ, RESP, Actions>>
    extends StatefulActions<CommandState<REQ, RESP>,
        CommandStateBuilder<REQ, RESP>, Actions> {
  ActionDispatcher<CommandPayload<REQ, RESP, Actions, String>> get $clear;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, String>> get $cancel;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, Command<REQ>>>
      get $execute;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>
      get $result;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, String>> get $detach;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, String>> get $attach;

  ActionDispatcher<CommandPayload<REQ, RESP, Actions, CommandProgress>>
      get $progress;

  Type get commandType => REQ.runtimeType;

  Serializer get commandSerializer => null;

  Type get responseType => RESP.runtimeType;

  Serializer get resultSerializer => null;

  Type get dispatcherType => CommandDispatcher;

  CommandFuture<REQ, RESP, Actions> newFuture(Command<REQ> command);

  void execute(Command<REQ> command) {
    final payload = payloadOf<Command<REQ>>(command);
    try {
      if (!$ensureState($store)) {
        throw StateError('Command state [${$name}] cannot be initialized. '
            'Parent state [${$options.parent.name}] is null');
      }
    } catch (e) {
      print(e);
    }
    $execute(payload);
  }

  @override
  void $reducer(ReducerBuilder reducer) {
    super.$reducer(reducer);
    reducer.nest(this)
      ..add($clear, (state, builder, action) {
        if (builder == null) {
          return;
        }
        builder.command = null;
        builder.result = null;
        builder.status = CommandStatus.idle;
      })
      ..add($detach, (s, b, a) {})
      ..add($cancel, (state, builder, action) {
        if (builder == null) return;
        builder?.status = CommandStatus.canceling;
      })
      ..add($execute, (state, builder,
          Action<CommandPayload<REQ, RESP, Actions, Command<REQ>>> action) {
        if (builder == null) return;
        // Set request.
        builder.command = action.payload.payload.toBuilder();
        // Set to 'calling'.
        builder.status = CommandStatus.executing;
      })
      ..add($progress, (state, builder,
          Action<CommandPayload<REQ, RESP, Actions, CommandProgress>> action) {
        if (builder == null) return;
        // Set progress.
        builder.progress = action.payload.payload.toBuilder();
      })
      ..add($result, (state,
          builder,
          Action<CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>
              action) {
        if (builder == null) return;
        final req = builder.command;
        if (req == null) return;
        final payload = action.payload?.payload;
        if (payload == null) {
          return;
        }
        if (req.id != payload.id) {
          return;
        }

        builder.result = payload.toBuilder();
        builder.status = CommandStatus.result;
      });
  }

  StoreSubscription<CommandPayload<REQ, RESP, Actions, Command<REQ>>> onExecute<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(
          Store<State, StateBuilder, StoreActions> store,
          Function(ModuxEvent<CommandPayload<REQ, RESP, Actions, Command<REQ>>>,
                  Command<REQ>, REQ)
              handler) =>
      store.listen<CommandPayload<REQ, RESP, Actions, Command<REQ>>>($execute,
          (event) {
        handler?.call(
            event, event?.value?.payload, event?.value?.payload?.payload);
      });

  StoreSubscription<
      CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>> observeResult<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(
                  ModuxEvent<
                      CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>,
                  CommandResult<RESP>,
                  RESP)
              handler]) =>
      store.listen<CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>(
          $result, (event) {
        handler?.call(
            event, event?.value?.payload, event?.value?.payload?.value);
      });

  StoreSubscription<
      CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>> onResult<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(
                  ModuxEvent<
                      CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>,
                  CommandResult<RESP>)
              handler]) =>
      store.listen<CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>(
          $result, (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<CommandPayload<REQ, RESP, Actions, String>> onClear<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(ModuxEvent<CommandPayload<REQ, RESP, Actions, String>>,
                  String)
              handler]) =>
      store.listen<CommandPayload<REQ, RESP, Actions, String>>($clear, (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<CommandPayload<REQ, RESP, Actions, String>> onCancel<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(ModuxEvent<CommandPayload<REQ, RESP, Actions, String>>,
                  String)
              handler]) =>
      store.listen<CommandPayload<REQ, RESP, Actions, String>>($cancel,
          (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<CommandPayload<REQ, RESP, Actions, CommandProgress>>
      onProgress<
                  State extends Built<State, StateBuilder>,
                  StateBuilder extends Builder<State, StateBuilder>,
                  StoreActions extends ModuxActions<State, StateBuilder,
                      StoreActions>>(
              Store<State, StateBuilder, StoreActions> store,
              [Function(
                      ModuxEvent<
                          CommandPayload<REQ, RESP, Actions, CommandProgress>>,
                      CommandProgress)
                  handler]) =>
          store.listen<CommandPayload<REQ, RESP, Actions, CommandProgress>>(
              $progress, (event) {
            handler?.call(event, event?.value?.payload);
          });

  @override
  @mustCallSuper
  void $middleware(MiddlewareBuilder builder) {
    super.$middleware(builder);
    builder.nest(this)
      ..add($clear, middlewareClear)
      ..add($cancel, middlewareCancel)
      ..add($result, middlewareResult)
      ..add($execute, middlewareExecute)
      ..add($progress, middlewareProgress);
  }

  CommandPayload<REQ, RESP, Actions, T> payloadOf<T>(T payload) =>
      (CommandPayloadBuilder<REQ, RESP, Actions, T>()
            ..dispatcher = this
            ..detached = false
            ..payload = payload)
          .build();

  void send(REQ request, {String id = '', int timeout = 15000}) =>
      $execute((CommandPayload<REQ, RESP, Actions, Command<REQ>>(
          Command<REQ>((b) => b
            ..id = id == null || id.isEmpty ? uuid.next() : id
            ..payload = request
            ..timeout = timeout),
          this)));

  ///
  void clear([String id]) =>
      $clear(CommandPayload<REQ, RESP, Actions, String>(id ?? '', this));

  ///
  void cancel([String id]) =>
      $clear(CommandPayload<REQ, RESP, Actions, String>(id ?? '', this));

  void detach([String id]) => cancel(id);

  ///
  @protected
  void middlewareExecute(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<REQ, RESP>,
              CommandStateBuilder<REQ, RESP>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<REQ, RESP, Actions, Command<REQ>>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareResult(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<REQ, RESP>,
              CommandStateBuilder<REQ, RESP>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<REQ, RESP, Actions, CommandResult<RESP>>>
          action) async {
    next(action);
  }

  ///
  @protected
  void middlewareCancel(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<REQ, RESP>,
              CommandStateBuilder<REQ, RESP>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<REQ, RESP, Actions, String>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareProgress(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<REQ, RESP>,
              CommandStateBuilder<REQ, RESP>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<REQ, RESP, Actions, CommandProgress>>
          action) async {
    next(action);
  }

  ///
  @protected
  void middlewareClear(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<REQ, RESP>,
              CommandStateBuilder<REQ, RESP>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<REQ, RESP, Actions, String>> action) async {
    next(action);
  }
}

abstract class CommandPayload<REQ, RESP,
        D extends CommandDispatcher<REQ, RESP, D>, P>
    implements
        Built<CommandPayload<REQ, RESP, D, P>,
            CommandPayloadBuilder<REQ, RESP, D, P>> {
  @nullable
  bool get detached;

  P get payload;

  D get dispatcher;

  Type get requestType => REQ;

  Type get responseType => RESP;

  Type get dispatcherType => D;

  CommandPayload._();

  factory CommandPayload(P payload, D dispatcher, [bool detached = false]) =>
      _$CommandPayload<REQ, RESP, D, P>((b) => b
        ..detached = detached
        ..payload = payload
        ..dispatcher = dispatcher);
}

@BuiltValue(wireName: 'redux/Command')
abstract class Command<REQ>
    implements Built<Command<REQ>, CommandBuilder<REQ>> {
  static Serializer<Command> get serializer => _$commandSerializer;

  String get id;

  REQ get payload;

  int get timeout;

  Type get payloadType => REQ;

  Command._();

  factory Command([updates(CommandBuilder<REQ> b)]) = _$Command<REQ>;

  factory Command.of(REQ payload, {String id = '', int timeout = 15000}) =>
      (CommandBuilder<REQ>()
            ..id = id == null || id.isEmpty ? uuid.next() : id
            ..timeout = timeout
            ..payload = payload)
          .build();
}

@BuiltValueEnum(wireName: 'redux/CommandStatus')
class CommandStatus extends EnumClass {
  static Serializer<CommandStatus> get serializer => _$commandStatusSerializer;

  @BuiltValueEnumConst(wireName: 'idle')
  static const CommandStatus idle = _$wireIdle;

  @BuiltValueEnumConst(wireName: 'result')
  static const CommandStatus result = _$wireResult;

  @BuiltValueEnumConst(wireName: 'executing')
  static const CommandStatus executing = _$wireExecuting;

  @BuiltValueEnumConst(wireName: 'canceling')
  static const CommandStatus canceling = _$wireCanceling;

  const CommandStatus._(String name) : super(name);

  static BuiltSet<CommandStatus> get values => _$commandStatusValues;

  static CommandStatus valueOf(String name) => _$commandStatusValueOf(name);
}

@BuiltValue(wireName: 'redux/CommandProgress')
abstract class CommandProgress
    implements Built<CommandProgress, CommandProgressBuilder> {
  DateTime get started;

  DateTime get timestamp;

  int get current;

  int get max;

  String get message;

  double get percentComplete {
    if (max <= current) {
      return 1.0;
    }
    return max != 0 && current != 0 ? max.toDouble() / current.toDouble() : 0.0;
  }

  Duration get remainingTime {
    final percentDone = percentComplete;
    if (percentComplete == 0) {
      return INF;
    }
    if (timestamp.millisecondsSinceEpoch < started.millisecondsSinceEpoch) {
      return INF;
    }
    final spent = timestamp.difference(started);
    return Duration(
        microseconds:
            spent.inMicroseconds ~/ percentDone - spent.inMicroseconds);
  }

  CommandProgress._();

  factory CommandProgress([updates(CommandProgressBuilder)]) =
      _$CommandProgress;

  static const Duration INF = Duration(seconds: -1);
}

@BuiltValue(wireName: 'redux/CommandResult')
abstract class CommandResult<RESP>
    implements Built<CommandResult<RESP>, CommandResultBuilder<RESP>> {
  static Serializer<CommandResult> get serializer => _$commandResultSerializer;

  String get id;

  CommandResultCode get code;

  @nullable
  String get message;

  DateTime get started;

  DateTime get timestamp;

  @nullable
  RESP get value;

  // Built value boilerplate
  CommandResult._();

  factory CommandResult([updates(CommandResultBuilder<RESP> b)]) =
      _$CommandResult<RESP>;

  bool get isErr => code != CommandResultCode.done;

  bool get isOk => !isErr;

  bool get isCanceled => code == CommandResultCode.canceled;
}

@BuiltValueEnum(wireName: 'redux/CommandResultCode')
class CommandResultCode extends EnumClass {
  static Serializer<CommandResultCode> get serializer =>
      _$commandResultCodeSerializer;

  static const CommandResultCode done = _$wireDone;
  static const CommandResultCode next = _$wireNext;
  static const CommandResultCode canceled = _$wireCanceled;
  static const CommandResultCode timeout = _$wireTimeout;
  static const CommandResultCode error = _$wireError;

  const CommandResultCode._(String name) : super(name);

  static BuiltSet<CommandResultCode> get values => _$commandResultCodeValues;

  static CommandResultCode valueOf(String name) =>
      _$commandResultCodeValueOf(name);
}

@BuiltValue(wireName: 'redux/CommandState', autoCreateNestedBuilders: false)
abstract class CommandState<REQ, RESP>
    implements Built<CommandState<REQ, RESP>, CommandStateBuilder<REQ, RESP>> {
  static Serializer<CommandState> get serializer => _$commandStateSerializer;

  @nullable
  CommandStatus get status;

  @nullable
  Command<REQ> get command;

  @nullable
  CommandResult<RESP> get result;

  @nullable
  CommandProgress get progress;

//  @nullable
//  BuiltList<CommandState<REQ, RESP>> get futures;

  bool get isInProgress => status == CommandStatus.executing;

  bool get isCompleted => status == CommandStatus.result;

  bool get isCanceled => result?.code == CommandResultCode.canceled ?? false;

  bool isActive(Command<REQ> command) => this.command == command;

  CommandState._();

  factory CommandState([updates(CommandStateBuilder<REQ, RESP> b)]) {
    return _$CommandState<REQ, RESP>((builder) {
      if (updates != null) updates(builder);

      if (builder.status == null) {
        if (builder.result != null) {
          builder.status = CommandStatus.result;
        } else {
          builder.status = CommandStatus.idle;
        }
      }
    });
  }
}

class CommandFutures {
  final Store store;
  final CommandDispatcher dispatcher;
  final Map<String, CommandFuture> futures = {};

  CommandFutures(this.store, this.dispatcher);

  CommandFuture newFuture(CommandPayload payload) {
    final id = payload?.payload?.id ?? '';
    final future = dispatcher.newFuture(payload.payload);

    if (future == null)
      throw StateError('CommandDispatcher '
          '[${dispatcher.$name}] '
          'of Type [${dispatcher.$actionsType}] '
          'newFuture() returned null');

    // Set owner.
    future._owner = this;

    // Replace existing if necessary.
    futures[id]?.replaced();
    futures[id] = future;

    // Start Future.
    future.start();

    return future;
  }

  void cancelAll() => futures.values.toList().forEach((f) => f.cancel());

  void cancelAllExcept(CommandFuture future) => futures.values
      .where((f) => f != future)
      .toList()
      .forEach((f) => f.cancel());

  _remove(CommandFuture future) {
    final existing = futures[future.id];
    if (existing == future) {
      futures.remove(future.id);
    }
  }
}

/// Future that handles the lifecycle of a Command.
/// This must be extended by the custom Command middleware.
abstract class CommandFuture<REQ, RESP,
    D extends CommandDispatcher<REQ, RESP, D>> {
  final D dispatcher;
  final DateTime started = DateTime.now();
  final Completer<CommandResult<RESP>> completer = Completer();
  final Command<REQ> command;
  CommandFutures _owner;

  Timer _timer;

  ///
  bool _detached = false;

  String get id => command?.id ?? '';

  CommandFutures get owner => _owner;

  Future<CommandResult<RESP>> get future => completer.future;

  bool get isCompleted => completer.isCompleted;

  bool get hasTimer => _timer != null;

  bool get isTimerActive => _timer?.isActive ?? false;

  Store get store => dispatcher.$store;

  Timer get timer => _timer;

  T storeService<T>() => dispatcher.$store.service<T>();

  CommandFuture(this.dispatcher, this.command);

  @mustCallSuper
  void start() {
    startTimer();
    execute();
  }

  void execute();

  void startTimer() {
    if (completer.isCompleted) return;
    if (_timer != null) return;
    if (command.timeout == null || command.timeout <= 0) return;
    _timer = Timer(Duration(milliseconds: command.timeout), () => timedOut());
  }

  void replaced() {
    complete(CommandResultCode.canceled, message: 'replaced');
  }

  void cancel([String msg]) {
    complete(CommandResultCode.canceled, message: msg);
  }

  void timedOut() {
    complete(CommandResultCode.timeout);
  }

  void complete(CommandResultCode code,
      {RESP response, String message = null}) {
    if (completer.isCompleted) return;
    completeResult((CommandResultBuilder<RESP>()
          ..id = command.id
          ..code = code
          ..started = started
          ..message = message
          ..value = response
          ..timestamp = DateTime.now())
        .build());
  }

  void completeResult(CommandResult<RESP> result) {
    if (isCompleted) return;
    try {
      _timer?.cancel();
      _timer = null;
      completer.complete(result);
    } catch (e) {
      // Ignore.
    } finally {
      try {
        if (!_detached) {
          dispatcher.$result(CommandPayload<REQ, RESP, D, CommandResult<RESP>>(
              result, dispatcher));
        }
      } catch (e) {}
      try {
        _owner?._remove(this);
      } catch (e) {}

      try {
        done(result);
      } finally {
        dispose();
      }
    }
  }

  @protected
  void done(CommandResult<RESP> result) {}

  void dispose() {}
}

abstract class CommandStreamFuture<REQ, RESP,
        D extends CommandDispatcher<REQ, RESP, D>>
    extends CommandFuture<REQ, RESP, D> {
  CommandStreamFuture(D dispatcher, Command<REQ> command)
      : super(dispatcher, command) {}

  void map<T>(Stream<T> stream, CommandResult<RESP> mapper(T),
      {CommandProgress progress(CommandResult<RESP> result)}) {
    stream
        .map(mapper)
        .listen(onData, onDone: onDone, onError: onError, cancelOnError: true);
  }

  @protected
  onDone() {}

  @protected
  onError(dynamic e) {}

  @protected
  onData(CommandResult<RESP> data) {
    next(data.value);
  }

  bool next(RESP response, {String message = null}) {
    if (completer.isCompleted) return false;

    dispatcher.$result(CommandPayload<REQ, RESP, D, CommandResult<RESP>>(
        (CommandResultBuilder<RESP>()
              ..id = command.id ?? ''
              ..code = CommandResultCode.next
              ..started = started
              ..message = message
              ..value = response
              ..timestamp = DateTime.now())
            .build(),
        dispatcher));

    return true;
  }
}
