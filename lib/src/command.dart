import 'dart:async';
import 'dart:collection';

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
  void call(REQ request,
          {String id = '', Duration timeout = const Duration(seconds: 30)}) =>
      execute$(Command<REQ>((b) => b
        ..id = id == null || id.isEmpty ? uuid.next() : id
        ..payload = request
        ..timeout = timeout));
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
  ActionDispatcher<String> get cancel$;

  ActionDispatcher<Command<Cmd>> get execute$;

  ActionDispatcher<CommandResult<Result>> get result$;

  ActionDispatcher<CommandProgress> get progress$;

  Type get commandType => Cmd.runtimeType;

  Type get resultType => Result.runtimeType;

  CommandFuture<Cmd, Result, Actions> newFuture(Command<Cmd> command);

  void execute(Command<Cmd> command) {
    try {
      if (!ensureState$()) {
        throw StateError('Command state [${name$}] cannot be initialized. '
            'Parent state [${options$.parent.name}] is null');
      }
    } catch (e) {
//      print(e);
    }
    execute$(command);
  }

  DispatcherFutures<Cmd, Result, Actions> get futures => store$.futuresOf(this);

  @override
  void reducer$(ReducerBuilder reducer) {
    super.reducer$(reducer);
    reducer.nest(this)
      ..add(cancel$, (state, builder, action) {
        if (builder == null) return;
        builder?.status = CommandStatus.canceling;
      })
      ..add(execute$, (state, builder, Action<Command<Cmd>> action) {
        if (builder == null) return;
        // Set request.
        builder.command = action.payload.toBuilder();
        // Set to 'calling'.
        builder.status = CommandStatus.executing;
      })
      ..add(progress$, (state, builder, Action<CommandProgress> action) {
        if (builder == null) return;
        // Set progress.
        builder.progress = action.payload?.toBuilder();
      })
      ..add(result$, (state, builder, Action<CommandResult<Result>> action) {
        if (builder == null) return;
        final req = builder.command;
        if (req == null) return;
        final payload = action.payload;
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

  StoreSubscription<Command<Cmd>> onExecute([Function(Command<Cmd>) handler]) =>
      handler != null
          ? store$.listen<Command<Cmd>>(execute$, handler)
          : store$.subscribe<Command<Cmd>>(execute$);

  StoreSubscription<CommandResult<Result>> onResult(
          [Function(CommandResult<Result> r) handler]) =>
      handler != null
          ? store$.listen<CommandResult<Result>>(result$, handler)
          : store$.subscribe<CommandResult<Result>>(result$);

  StoreSubscription<String> onCancel([Function(String) handler]) =>
      handler != null
          ? store$.listen<String>(cancel$, handler)
          : store$.subscribe<String>(cancel$);

  StoreSubscription<CommandProgress> onProgress(
          [Function(CommandProgress) handler]) =>
      handler != null
          ? store$.listen<CommandProgress>(progress$, handler)
          : store$.subscribe<CommandProgress>(progress$);

  @override
  @mustCallSuper
  void middleware$(MiddlewareBuilder builder) {
    super.middleware$(builder);
    builder.nest(this)
      ..add(cancel$, middlewareCancel)
      ..add(result$, middlewareResult)
      ..add(execute$, middlewareExecute)
      ..add(progress$, middlewareProgress);
  }

  Future<CommandResult<Result>> future(Cmd request,
      {String id = '', Duration timeout = Duration.zero}) {
    return store$.execute(this, request, timeout: timeout);
  }

  void send(Cmd request, {String id = '', Duration timeout = Duration.zero}) =>
      execute$(Command<Cmd>((b) => b
        ..id = id == null || id.isEmpty
            ? request.hashCode?.toString() ?? uuid.next()
            : id
        ..payload = request
        ..timeout = timeout));

  ///
  void cancel([String id]) => cancel$(id ?? '');

  ///
  @protected
  void middlewareExecute(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<Command<Cmd>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareResult(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandResult<Result>> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareCancel(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<String> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareProgress(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<CommandProgress> action) async {
    next(action);
  }

  ///
  @protected
  void middlewareClear(
      NestedMiddlewareApi<dynamic, dynamic, dynamic, CommandState<Cmd, Result>,
              CommandStateBuilder<Cmd, Result>, Actions>
          api,
      ActionHandler next,
      Action<String> action) async {
    next(action);
  }
}

//abstract class CommandPayload<D extends CommandDispatcher<dynamic, dynamic, D>,
//        P>
//    implements
//        Built<CommandPayload<REQ, RESP, D, P>,
//            CommandPayloadBuilder<REQ, RESP, D, P>> {
//  P get payload;
//
//  D get dispatcher;
//
//  @nullable
//  CommandFuture get future;
//
//  Type get requestType => REQ;
//
//  Type get responseType => RESP;
//
//  Type get dispatcherType => D;
//
//  CommandPayload._();
//
//  factory CommandPayload(P payload, D dispatcher) =>
//      _$CommandPayload<REQ, RESP, D, P>((b) => b
//        ..payload = payload
//        ..dispatcher = dispatcher);
//}

@BuiltValue(wireName: 'modux/Command')
abstract class Command<REQ>
    implements Built<Command<REQ>, CommandBuilder<REQ>> {
  static Serializer<Command> get serializer => _$commandSerializer;

  String get uid;

  String get id;

  REQ get payload;

  Duration get timeout;

  Type get payloadType => REQ;

  bool get hasTimeout =>
      timeout != null || timeout == Duration.zero || timeout.isNegative;

  Command._();

  factory Command([updates(CommandBuilder<REQ> b)]) => _$Command<REQ>((b) {
        updates?.call(b);
        b..uid = uuid.next();
      });

  factory Command.of(REQ payload,
          {String id = '', Duration timeout = Duration.zero}) =>
      (CommandBuilder<REQ>()
            ..uid = uuid.next()
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

///
class DispatcherFutures<Req, Resp,
    Actions extends CommandDispatcher<Req, Resp, Actions>> {
  DispatcherFutures(
      this.key, this.store, this.storeMap, this.storeFutures, this.dispatcher);

  final String key;
  final Store store;
  final LinkedHashMap<String, DispatcherFutures> storeMap;
  final LinkedHashMap<String, CommandFuture> storeFutures;
  final CommandDispatcher dispatcher;
  final futures = LinkedHashMap<String, CommandFuture<Req, Resp, Actions>>();

  bool get isEmpty => futures.isEmpty;

  void keepNewest(int size) {
    if (futures.length <= size) return;
    var count = futures.length - size;
    final iterator = futures.values.iterator;
    while (iterator.moveNext() && count > 0) {
      iterator.current.cancel();
      count--;
    }
  }

  void register(CommandFuture<Req, Resp, Actions> future) {
    if (future.command?.id != null)
      futures.remove(future.command.id)?.replaced();
    futures[future.command.id] = future;
  }

  void cancelAll() => futures.values.toList().forEach((f) => f.cancel());

  void cancelAllExcept(CommandFuture<Req, Resp, Actions> future) =>
      futures.values
          .where((f) => f != future)
          .toList()
          .forEach((f) => f.cancel());

  void _remove(CommandFuture<Req, Resp, Actions> future) {
    final existing = futures[future.id];
    if (existing == future) {
      futures.remove(future.id);
    }
    storeFutures.remove(future.uid);
    if (futures.isEmpty) {
      storeMap.remove(key);
    }
  }
}

abstract class CancelableFuture<T> implements Future<T> {
  void cancel();
}

/// Future that handles the lifecycle of a Command.
/// This must be extended by the custom Command middleware.
abstract class CommandFuture<REQ, RESP,
        D extends CommandDispatcher<REQ, RESP, D>>
    implements CancelableFuture<CommandResult<RESP>> {
  final String uid = uuid.next();
  final D dispatcher;
  final DateTime started = DateTime.now();
  final Completer<CommandResult<RESP>> completer = Completer();
  final Command<REQ> command;
  DispatcherFutures _owner;
  bool _cancelDispatched = false;
  bool _canceling = false;
  bool _disposed = false;

  Timer _timer;

  ///
  bool _detached = false;

  String get id => command?.id ?? '';

  DispatcherFutures get owner => _owner;

  Future<CommandResult<RESP>> get future => completer.future;

  bool get isCompleted => completer.isCompleted;

  bool get hasTimer => _timer != null;

  bool get isTimerActive => _timer?.isActive ?? false;

  Store get store => dispatcher.store$;

  Timer get timer => _timer;

  T storeService<T>() => dispatcher.store$.service<T>();

  CommandFuture(this.dispatcher, this.command) {
    completer.future.then((result) {
      try {
        _owner?._remove(this);
      } catch (e) {}
      try {
        done(result);
      } finally {
        if (_disposed) return;
        _disposed = true;
        dispose();
      }
    });
  }

  @mustCallSuper
  void start() {
    startTimer();
    execute();
  }

  void execute();

  void startTimer() {
    if (completer.isCompleted) return;
    if (_timer != null) return;
    if (command.timeout == null ||
        command.timeout == Duration.zero ||
        command.timeout.isNegative) return;
    _timer = Timer(command.timeout, () => timedOut());
  }

  void replaced() {
    complete(CommandResultCode.canceled, message: 'replaced');
  }

  void receivedCancel() {
    _cancelDispatched = true;
    if (_canceling) return;
    cancel();
  }

  void notifyCancel() {
    dispatcher?.cancel(id);
  }

  void cancel() {
    if (_canceling) return;
    _canceling = true;
    if (!_cancelDispatched) {
      try {
        _cancelDispatched = true;
        notifyCancel();
      } catch (e) {}
    }
    executeCancel();
  }

  @protected
  void executeCancel() {
    complete(CommandResultCode.canceled);
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

    _timer?.cancel();
    _timer = null;

    try {
      if (!_detached) {
        dispatcher?.result$?.call(result);
      }
    } catch (e) {}

    try {
      completer.complete(result);
    } catch (e) {}
  }

  @protected
  void done(CommandResult<RESP> result) {}

  void dispose() {}

  @override
  Future<CommandResult<RESP>> timeout(Duration timeLimit,
          {FutureOr<CommandResult<RESP>> onTimeout()}) =>
      completer.future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<CommandResult<RESP>> asStream() => completer.future.asStream();

  @override
  Future<CommandResult<RESP>> whenComplete(FutureOr action()) =>
      completer.future.whenComplete(action);

  @override
  Future<CommandResult<RESP>> catchError(Function onError,
          {bool test(bool test(Object error))}) =>
      completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> onValue(CommandResult<RESP> value),
          {Function onError}) =>
      completer.future.then<R>(onValue);
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

    dispatcher.result$((CommandResultBuilder<RESP>()
          ..id = command.id ?? ''
          ..code = CommandResultCode.next
          ..started = started
          ..message = message
          ..value = response
          ..timestamp = DateTime.now())
        .build());

    return true;
  }
}
