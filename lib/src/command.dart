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

abstract class BuiltCommandDispatcher<
    Cmd extends Built<Cmd, CmdBuilder>,
    CmdBuilder extends Builder<Cmd, CmdBuilder>,
    Result extends Built<Result, ResultBuilder>,
    ResultBuilder extends Builder<Result, ResultBuilder>,
    Actions extends BuiltCommandDispatcher<
        Cmd,
        CmdBuilder,
        Result,
        ResultBuilder,
        Actions>> extends CommandDispatcher<Cmd, Result, Actions> {
  CmdBuilder newCommandBuilder();

  ResultBuilder newResultBuilder();

  Serializer get commandSerializer => null;

  Serializer get resultSerializer => null;
}

abstract class NestedBuiltCommandDispatcher<
    Cmd extends Built<Cmd, CmdBuilder>,
    CmdBuilder extends Builder<Cmd, CmdBuilder>,
    CmdPayload extends Built<CmdPayload, CmdPayloadBuilder>,
    CmdPayloadBuilder extends Builder<CmdPayload, CmdPayloadBuilder>,
    Result extends Built<Result, ResultBuilder>,
    ResultBuilder extends Builder<Result, ResultBuilder>,
    ResultPayload extends Built<ResultPayload, ResultPayloadBuilder>,
    ResultPayloadBuilder extends Builder<ResultPayload, ResultPayloadBuilder>,
    Actions extends NestedBuiltCommandDispatcher<
        Cmd,
        CmdBuilder,
        CmdPayload,
        CmdPayloadBuilder,
        Result,
        ResultBuilder,
        ResultPayload,
        ResultPayloadBuilder,
        Actions>> extends BuiltCommandDispatcher<Cmd, CmdBuilder, Result,
    ResultBuilder, Actions> {
  CmdPayloadBuilder newCommandPayloadBuilder();

  ResultPayloadBuilder newResultPayloadBuilder();

  Serializer get commandPayloadSerializer => null;

  Serializer get resultPayloadSerializer => null;
}

///
abstract class CommandDispatcher<Cmd, Result,
        Actions extends CommandDispatcher<Cmd, Result, Actions>>
    extends StatefulActions<CommandState<Cmd, Result>,
        CommandStateBuilder<Cmd, Result>, Actions> {
  ActionDispatcher<CommandPayload<Cmd, Result, Actions, String>> get $clear;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, String>> get $cancel;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, Command<Cmd>>>
      get $execute;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, CommandResult<Result>>>
      get $result;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, String>> get $detach;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, String>> get $attach;

  ActionDispatcher<CommandPayload<Cmd, Result, Actions, CommandProgress>>
      get $progress;

  Type get commandType => Cmd.runtimeType;

  Type get resultType => Result.runtimeType;

  CommandFuture<Cmd, Result, Actions> newFuture(Command<Cmd> command);

  void execute(Command<Cmd> command) {
    final payload = payloadOf<Command<Cmd>>(command);
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
          Action<CommandPayload<Cmd, Result, Actions, Command<Cmd>>> action) {
        if (builder == null) return;
        // Set request.
        builder.command = action.payload.payload.toBuilder();
        // Set to 'calling'.
        builder.status = CommandStatus.executing;
      })
      ..add($progress, (state,
          builder,
          Action<CommandPayload<Cmd, Result, Actions, CommandProgress>>
              action) {
        if (builder == null) return;
        // Set progress.
        builder.progress = action.payload.payload.toBuilder();
      })
      ..add($result, (state,
          builder,
          Action<CommandPayload<Cmd, Result, Actions, CommandResult<Result>>>
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

  StoreSubscription<CommandPayload<Cmd, Result, Actions, Command<Cmd>>>
      onExecute<
                  State extends Built<State, StateBuilder>,
                  StateBuilder extends Builder<State, StateBuilder>,
                  StoreActions extends ModuxActions<State, StateBuilder,
                      StoreActions>>(
              Store<State, StateBuilder, StoreActions> store,
              Function(
                      ModuxEvent<
                          CommandPayload<Cmd, Result, Actions, Command<Cmd>>>,
                      Command<Cmd>)
                  handler) =>
          store.listen<CommandPayload<Cmd, Result, Actions, Command<Cmd>>>(
              $execute, (event) {
            handler?.call(event, event?.value?.payload);
          });

  StoreSubscription<
      CommandPayload<Cmd, Result, Actions, CommandResult<Result>>> onResult<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(
                  ModuxEvent<
                      CommandPayload<Cmd, Result, Actions,
                          CommandResult<Result>>>,
                  CommandResult<Result>)
              handler]) =>
      store.listen<CommandPayload<Cmd, Result, Actions, CommandResult<Result>>>(
          $result, (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<CommandPayload<Cmd, Result, Actions, String>> onClear<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(ModuxEvent<CommandPayload<Cmd, Result, Actions, String>>,
                  String)
              handler]) =>
      store.listen<CommandPayload<Cmd, Result, Actions, String>>($clear,
          (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<CommandPayload<Cmd, Result, Actions, String>> onCancel<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(ModuxEvent<CommandPayload<Cmd, Result, Actions, String>>,
                  String)
              handler]) =>
      store.listen<CommandPayload<Cmd, Result, Actions, String>>($cancel,
          (event) {
        handler?.call(event, event?.value?.payload);
      });

  StoreSubscription<
      CommandPayload<Cmd, Result, Actions, CommandProgress>> onProgress<
              State extends Built<State, StateBuilder>,
              StateBuilder extends Builder<State, StateBuilder>,
              StoreActions extends ModuxActions<State, StateBuilder,
                  StoreActions>>(Store<State, StateBuilder, StoreActions> store,
          [Function(
                  ModuxEvent<
                      CommandPayload<Cmd, Result, Actions, CommandProgress>>,
                  CommandProgress)
              handler]) =>
      store.listen<CommandPayload<Cmd, Result, Actions, CommandProgress>>(
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

  CommandPayload<Cmd, Result, Actions, T> payloadOf<T>(T payload) =>
      (CommandPayloadBuilder<Cmd, Result, Actions, T>()
            ..dispatcher = this
            ..detached = false
            ..payload = payload)
          .build();

  void send(Cmd request, {String id = '', int timeout = 15000}) =>
      $execute((CommandPayload<Cmd, Result, Actions, Command<Cmd>>(
          Command<Cmd>((b) => b
            ..id = id == null || id.isEmpty ? uuid.next() : id
            ..payload = request
            ..timeout = timeout),
          this)));

  ///
  void clear([String id]) =>
      $clear(CommandPayload<Cmd, Result, Actions, String>(id ?? '', this));

  ///
  void cancel([String id]) =>
      $clear(CommandPayload<Cmd, Result, Actions, String>(id ?? '', this));

  void detach([String id]) => cancel(id);

  ///
  @protected
  void middlewareExecute(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<Cmd, Result, Actions, Command<Cmd>>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareResult(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<Cmd, Result, Actions, CommandResult<Result>>>
          action) async {
    next(action);
  }

  ///
  @protected
  void middlewareCancel(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<Cmd, Result, Actions, String>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareProgress(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<Cmd, Result, Actions, CommandProgress>>
          action) async {
    next(action);
  }

  ///
  @protected
  void middlewareClear(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandPayload<Cmd, Result, Actions, String>> action) async {
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

@BuiltValue(wireName: 'modux/Command')
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

@BuiltValueEnum(wireName: 'modux/CommandStatus')
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

@BuiltValue(wireName: 'modux/CommandProgress')
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

@BuiltValue(wireName: 'modux/CommandResult')
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

@BuiltValueEnum(wireName: 'modux/CommandResultCode')
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

@BuiltValue(wireName: 'modux/CommandState', autoCreateNestedBuilders: false)
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
