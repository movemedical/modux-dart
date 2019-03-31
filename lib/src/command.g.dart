// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CommandStatus _$wireIdle = const CommandStatus._('idle');
const CommandStatus _$wireResult = const CommandStatus._('result');
const CommandStatus _$wireExecuting = const CommandStatus._('executing');
const CommandStatus _$wireCanceling = const CommandStatus._('canceling');

CommandStatus _$commandStatusValueOf(String name) {
  switch (name) {
    case 'idle':
      return _$wireIdle;
    case 'result':
      return _$wireResult;
    case 'executing':
      return _$wireExecuting;
    case 'canceling':
      return _$wireCanceling;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<CommandStatus> _$commandStatusValues =
    new BuiltSet<CommandStatus>(const <CommandStatus>[
  _$wireIdle,
  _$wireResult,
  _$wireExecuting,
  _$wireCanceling,
]);

const CommandResultCode _$wireDone = const CommandResultCode._('done');
const CommandResultCode _$wireNext = const CommandResultCode._('next');
const CommandResultCode _$wireCanceled = const CommandResultCode._('canceled');
const CommandResultCode _$wireTimeout = const CommandResultCode._('timeout');
const CommandResultCode _$wireError = const CommandResultCode._('error');

CommandResultCode _$commandResultCodeValueOf(String name) {
  switch (name) {
    case 'done':
      return _$wireDone;
    case 'next':
      return _$wireNext;
    case 'canceled':
      return _$wireCanceled;
    case 'timeout':
      return _$wireTimeout;
    case 'error':
      return _$wireError;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<CommandResultCode> _$commandResultCodeValues =
    new BuiltSet<CommandResultCode>(const <CommandResultCode>[
  _$wireDone,
  _$wireNext,
  _$wireCanceled,
  _$wireTimeout,
  _$wireError,
]);

Serializer<Command> _$commandSerializer = new _$CommandSerializer();
Serializer<CommandStatus> _$commandStatusSerializer =
    new _$CommandStatusSerializer();
Serializer<CommandResult> _$commandResultSerializer =
    new _$CommandResultSerializer();
Serializer<CommandResultCode> _$commandResultCodeSerializer =
    new _$CommandResultCodeSerializer();
Serializer<CommandState> _$commandStateSerializer =
    new _$CommandStateSerializer();

class _$CommandSerializer implements StructuredSerializer<Command> {
  @override
  final Iterable<Type> types = const [Command, _$Command];
  @override
  final String wireName = 'redux/Command';

  @override
  Iterable serialize(Serializers serializers, Command object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterREQ =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
      'payload',
      serializers.serialize(object.payload, specifiedType: parameterREQ),
      'timeout',
      serializers.serialize(object.timeout, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  Command deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterREQ =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new CommandBuilder<Object>()
        : serializers.newBuilder(specifiedType) as CommandBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'payload':
          result.payload =
              serializers.deserialize(value, specifiedType: parameterREQ);
          break;
        case 'timeout':
          result.timeout = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$CommandStatusSerializer implements PrimitiveSerializer<CommandStatus> {
  static const Map<String, String> _toWire = const <String, String>{
    'idle': 'idle',
    'result': 'result',
    'executing': 'executing',
    'canceling': 'canceling',
  };
  static const Map<String, String> _fromWire = const <String, String>{
    'idle': 'idle',
    'result': 'result',
    'executing': 'executing',
    'canceling': 'canceling',
  };

  @override
  final Iterable<Type> types = const <Type>[CommandStatus];
  @override
  final String wireName = 'redux/CommandStatus';

  @override
  Object serialize(Serializers serializers, CommandStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CommandStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CommandStatus.valueOf(_fromWire[serialized] ?? serialized as String);
}

class _$CommandResultSerializer implements StructuredSerializer<CommandResult> {
  @override
  final Iterable<Type> types = const [CommandResult, _$CommandResult];
  @override
  final String wireName = 'redux/CommandResult';

  @override
  Iterable serialize(Serializers serializers, CommandResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterRESP =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
      'code',
      serializers.serialize(object.code,
          specifiedType: const FullType(CommandResultCode)),
      'started',
      serializers.serialize(object.started,
          specifiedType: const FullType(DateTime)),
      'timestamp',
      serializers.serialize(object.timestamp,
          specifiedType: const FullType(DateTime)),
    ];
    if (object.message != null) {
      result
        ..add('message')
        ..add(serializers.serialize(object.message,
            specifiedType: const FullType(String)));
    }
    if (object.value != null) {
      result
        ..add('value')
        ..add(
            serializers.serialize(object.value, specifiedType: parameterRESP));
    }

    return result;
  }

  @override
  CommandResult deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterRESP =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new CommandResultBuilder<Object>()
        : serializers.newBuilder(specifiedType) as CommandResultBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'code':
          result.code = serializers.deserialize(value,
                  specifiedType: const FullType(CommandResultCode))
              as CommandResultCode;
          break;
        case 'message':
          result.message = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'started':
          result.started = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime;
          break;
        case 'timestamp':
          result.timestamp = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime;
          break;
        case 'value':
          result.value =
              serializers.deserialize(value, specifiedType: parameterRESP);
          break;
      }
    }

    return result.build();
  }
}

class _$CommandResultCodeSerializer
    implements PrimitiveSerializer<CommandResultCode> {
  @override
  final Iterable<Type> types = const <Type>[CommandResultCode];
  @override
  final String wireName = 'redux/CommandResultCode';

  @override
  Object serialize(Serializers serializers, CommandResultCode object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  CommandResultCode deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CommandResultCode.valueOf(serialized as String);
}

class _$CommandStateSerializer implements StructuredSerializer<CommandState> {
  @override
  final Iterable<Type> types = const [CommandState, _$CommandState];
  @override
  final String wireName = 'redux/CommandState';

  @override
  Iterable serialize(Serializers serializers, CommandState object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterREQ =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];
    final parameterRESP =
        isUnderspecified ? FullType.object : specifiedType.parameters[1];

    final result = <Object>[];
    if (object.status != null) {
      result
        ..add('status')
        ..add(serializers.serialize(object.status,
            specifiedType: const FullType(CommandStatus)));
    }
    if (object.command != null) {
      result
        ..add('command')
        ..add(serializers.serialize(object.command,
            specifiedType: new FullType(Command, [parameterREQ])));
    }
    if (object.result != null) {
      result
        ..add('result')
        ..add(serializers.serialize(object.result,
            specifiedType: new FullType(CommandResult, [parameterRESP])));
    }
    if (object.progress != null) {
      result
        ..add('progress')
        ..add(serializers.serialize(object.progress,
            specifiedType: const FullType(CommandProgress)));
    }

    return result;
  }

  @override
  CommandState deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterREQ =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];
    final parameterRESP =
        isUnderspecified ? FullType.object : specifiedType.parameters[1];

    final result = isUnderspecified
        ? new CommandStateBuilder<Object, Object>()
        : serializers.newBuilder(specifiedType) as CommandStateBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(CommandStatus)) as CommandStatus;
          break;
        case 'command':
          if (result.command == null)
            result.command =
                serializers.newBuilder(new FullType(Command, [parameterREQ]));
          result.command.replace(serializers.deserialize(value,
                  specifiedType: new FullType(Command, [parameterREQ]))
              as Command<Object>);
          break;
        case 'result':
          if (result.result == null)
            result.result = serializers
                .newBuilder(new FullType(CommandResult, [parameterRESP]));
          result.result.replace(serializers.deserialize(value,
                  specifiedType: new FullType(CommandResult, [parameterRESP]))
              as CommandResult<Object>);
          break;
        case 'progress':
          if (result.progress == null)
            result.progress =
                serializers.newBuilder(const FullType(CommandProgress));
          result.progress.replace(serializers.deserialize(value,
                  specifiedType: const FullType(CommandProgress))
              as CommandProgress);
          break;
      }
    }

    return result.build();
  }
}

class _$CommandPayload<REQ, RESP, D extends CommandDispatcher<REQ, RESP, D>, P>
    extends CommandPayload<REQ, RESP, D, P> {
  @override
  final bool detached;
  @override
  final P payload;
  @override
  final D dispatcher;

  factory _$CommandPayload(
          [void updates(CommandPayloadBuilder<REQ, RESP, D, P> b)]) =>
      (new CommandPayloadBuilder<REQ, RESP, D, P>()..update(updates)).build();

  _$CommandPayload._({this.detached, this.payload, this.dispatcher})
      : super._() {
    if (payload == null) {
      throw new BuiltValueNullFieldError('CommandPayload', 'payload');
    }
    if (dispatcher == null) {
      throw new BuiltValueNullFieldError('CommandPayload', 'dispatcher');
    }
    if (REQ == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandPayload', 'REQ');
    }
    if (RESP == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandPayload', 'RESP');
    }
    if (D == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandPayload', 'D');
    }
    if (P == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandPayload', 'P');
    }
  }

  @override
  CommandPayload<REQ, RESP, D, P> rebuild(
          void updates(CommandPayloadBuilder<REQ, RESP, D, P> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandPayloadBuilder<REQ, RESP, D, P> toBuilder() =>
      new CommandPayloadBuilder<REQ, RESP, D, P>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandPayload &&
        detached == other.detached &&
        payload == other.payload &&
        dispatcher == other.dispatcher;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, detached.hashCode), payload.hashCode), dispatcher.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CommandPayload')
          ..add('detached', detached)
          ..add('payload', payload)
          ..add('dispatcher', dispatcher))
        .toString();
  }
}

class CommandPayloadBuilder<REQ, RESP,
        D extends CommandDispatcher<REQ, RESP, D>, P>
    implements
        Builder<CommandPayload<REQ, RESP, D, P>,
            CommandPayloadBuilder<REQ, RESP, D, P>> {
  _$CommandPayload<REQ, RESP, D, P> _$v;

  bool _detached;
  bool get detached => _$this._detached;
  set detached(bool detached) => _$this._detached = detached;

  P _payload;
  P get payload => _$this._payload;
  set payload(P payload) => _$this._payload = payload;

  D _dispatcher;
  D get dispatcher => _$this._dispatcher;
  set dispatcher(D dispatcher) => _$this._dispatcher = dispatcher;

  CommandPayloadBuilder();

  CommandPayloadBuilder<REQ, RESP, D, P> get _$this {
    if (_$v != null) {
      _detached = _$v.detached;
      _payload = _$v.payload;
      _dispatcher = _$v.dispatcher;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandPayload<REQ, RESP, D, P> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CommandPayload<REQ, RESP, D, P>;
  }

  @override
  void update(void updates(CommandPayloadBuilder<REQ, RESP, D, P> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$CommandPayload<REQ, RESP, D, P> build() {
    final _$result = _$v ??
        new _$CommandPayload<REQ, RESP, D, P>._(
            detached: detached, payload: payload, dispatcher: dispatcher);
    replace(_$result);
    return _$result;
  }
}

class _$Command<REQ> extends Command<REQ> {
  @override
  final String id;
  @override
  final REQ payload;
  @override
  final int timeout;

  factory _$Command([void updates(CommandBuilder<REQ> b)]) =>
      (new CommandBuilder<REQ>()..update(updates)).build();

  _$Command._({this.id, this.payload, this.timeout}) : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('Command', 'id');
    }
    if (payload == null) {
      throw new BuiltValueNullFieldError('Command', 'payload');
    }
    if (timeout == null) {
      throw new BuiltValueNullFieldError('Command', 'timeout');
    }
    if (REQ == dynamic) {
      throw new BuiltValueMissingGenericsError('Command', 'REQ');
    }
  }

  @override
  Command<REQ> rebuild(void updates(CommandBuilder<REQ> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandBuilder<REQ> toBuilder() => new CommandBuilder<REQ>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Command &&
        id == other.id &&
        payload == other.payload &&
        timeout == other.timeout;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, id.hashCode), payload.hashCode), timeout.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Command')
          ..add('id', id)
          ..add('payload', payload)
          ..add('timeout', timeout))
        .toString();
  }
}

class CommandBuilder<REQ>
    implements Builder<Command<REQ>, CommandBuilder<REQ>> {
  _$Command<REQ> _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  REQ _payload;
  REQ get payload => _$this._payload;
  set payload(REQ payload) => _$this._payload = payload;

  int _timeout;
  int get timeout => _$this._timeout;
  set timeout(int timeout) => _$this._timeout = timeout;

  CommandBuilder();

  CommandBuilder<REQ> get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _payload = _$v.payload;
      _timeout = _$v.timeout;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Command<REQ> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Command<REQ>;
  }

  @override
  void update(void updates(CommandBuilder<REQ> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Command<REQ> build() {
    final _$result =
        _$v ?? new _$Command<REQ>._(id: id, payload: payload, timeout: timeout);
    replace(_$result);
    return _$result;
  }
}

class _$CommandProgress extends CommandProgress {
  @override
  final DateTime started;
  @override
  final DateTime timestamp;
  @override
  final int current;
  @override
  final int max;
  @override
  final String message;

  factory _$CommandProgress([void updates(CommandProgressBuilder b)]) =>
      (new CommandProgressBuilder()..update(updates)).build();

  _$CommandProgress._(
      {this.started, this.timestamp, this.current, this.max, this.message})
      : super._() {
    if (started == null) {
      throw new BuiltValueNullFieldError('CommandProgress', 'started');
    }
    if (timestamp == null) {
      throw new BuiltValueNullFieldError('CommandProgress', 'timestamp');
    }
    if (current == null) {
      throw new BuiltValueNullFieldError('CommandProgress', 'current');
    }
    if (max == null) {
      throw new BuiltValueNullFieldError('CommandProgress', 'max');
    }
    if (message == null) {
      throw new BuiltValueNullFieldError('CommandProgress', 'message');
    }
  }

  @override
  CommandProgress rebuild(void updates(CommandProgressBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandProgressBuilder toBuilder() =>
      new CommandProgressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandProgress &&
        started == other.started &&
        timestamp == other.timestamp &&
        current == other.current &&
        max == other.max &&
        message == other.message;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, started.hashCode), timestamp.hashCode),
                current.hashCode),
            max.hashCode),
        message.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CommandProgress')
          ..add('started', started)
          ..add('timestamp', timestamp)
          ..add('current', current)
          ..add('max', max)
          ..add('message', message))
        .toString();
  }
}

class CommandProgressBuilder
    implements Builder<CommandProgress, CommandProgressBuilder> {
  _$CommandProgress _$v;

  DateTime _started;
  DateTime get started => _$this._started;
  set started(DateTime started) => _$this._started = started;

  DateTime _timestamp;
  DateTime get timestamp => _$this._timestamp;
  set timestamp(DateTime timestamp) => _$this._timestamp = timestamp;

  int _current;
  int get current => _$this._current;
  set current(int current) => _$this._current = current;

  int _max;
  int get max => _$this._max;
  set max(int max) => _$this._max = max;

  String _message;
  String get message => _$this._message;
  set message(String message) => _$this._message = message;

  CommandProgressBuilder();

  CommandProgressBuilder get _$this {
    if (_$v != null) {
      _started = _$v.started;
      _timestamp = _$v.timestamp;
      _current = _$v.current;
      _max = _$v.max;
      _message = _$v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandProgress other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CommandProgress;
  }

  @override
  void update(void updates(CommandProgressBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$CommandProgress build() {
    final _$result = _$v ??
        new _$CommandProgress._(
            started: started,
            timestamp: timestamp,
            current: current,
            max: max,
            message: message);
    replace(_$result);
    return _$result;
  }
}

class _$CommandResult<RESP> extends CommandResult<RESP> {
  @override
  final String id;
  @override
  final CommandResultCode code;
  @override
  final String message;
  @override
  final DateTime started;
  @override
  final DateTime timestamp;
  @override
  final RESP value;

  factory _$CommandResult([void updates(CommandResultBuilder<RESP> b)]) =>
      (new CommandResultBuilder<RESP>()..update(updates)).build();

  _$CommandResult._(
      {this.id,
      this.code,
      this.message,
      this.started,
      this.timestamp,
      this.value})
      : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('CommandResult', 'id');
    }
    if (code == null) {
      throw new BuiltValueNullFieldError('CommandResult', 'code');
    }
    if (started == null) {
      throw new BuiltValueNullFieldError('CommandResult', 'started');
    }
    if (timestamp == null) {
      throw new BuiltValueNullFieldError('CommandResult', 'timestamp');
    }
    if (RESP == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandResult', 'RESP');
    }
  }

  @override
  CommandResult<RESP> rebuild(void updates(CommandResultBuilder<RESP> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandResultBuilder<RESP> toBuilder() =>
      new CommandResultBuilder<RESP>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandResult &&
        id == other.id &&
        code == other.code &&
        message == other.message &&
        started == other.started &&
        timestamp == other.timestamp &&
        value == other.value;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, id.hashCode), code.hashCode), message.hashCode),
                started.hashCode),
            timestamp.hashCode),
        value.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CommandResult')
          ..add('id', id)
          ..add('code', code)
          ..add('message', message)
          ..add('started', started)
          ..add('timestamp', timestamp)
          ..add('value', value))
        .toString();
  }
}

class CommandResultBuilder<RESP>
    implements Builder<CommandResult<RESP>, CommandResultBuilder<RESP>> {
  _$CommandResult<RESP> _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  CommandResultCode _code;
  CommandResultCode get code => _$this._code;
  set code(CommandResultCode code) => _$this._code = code;

  String _message;
  String get message => _$this._message;
  set message(String message) => _$this._message = message;

  DateTime _started;
  DateTime get started => _$this._started;
  set started(DateTime started) => _$this._started = started;

  DateTime _timestamp;
  DateTime get timestamp => _$this._timestamp;
  set timestamp(DateTime timestamp) => _$this._timestamp = timestamp;

  RESP _value;
  RESP get value => _$this._value;
  set value(RESP value) => _$this._value = value;

  CommandResultBuilder();

  CommandResultBuilder<RESP> get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _code = _$v.code;
      _message = _$v.message;
      _started = _$v.started;
      _timestamp = _$v.timestamp;
      _value = _$v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandResult<RESP> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CommandResult<RESP>;
  }

  @override
  void update(void updates(CommandResultBuilder<RESP> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$CommandResult<RESP> build() {
    final _$result = _$v ??
        new _$CommandResult<RESP>._(
            id: id,
            code: code,
            message: message,
            started: started,
            timestamp: timestamp,
            value: value);
    replace(_$result);
    return _$result;
  }
}

class _$CommandState<REQ, RESP> extends CommandState<REQ, RESP> {
  @override
  final CommandStatus status;
  @override
  final Command<REQ> command;
  @override
  final CommandResult<RESP> result;
  @override
  final CommandProgress progress;

  factory _$CommandState([void updates(CommandStateBuilder<REQ, RESP> b)]) =>
      (new CommandStateBuilder<REQ, RESP>()..update(updates)).build();

  _$CommandState._({this.status, this.command, this.result, this.progress})
      : super._() {
    if (REQ == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandState', 'REQ');
    }
    if (RESP == dynamic) {
      throw new BuiltValueMissingGenericsError('CommandState', 'RESP');
    }
  }

  @override
  CommandState<REQ, RESP> rebuild(
          void updates(CommandStateBuilder<REQ, RESP> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandStateBuilder<REQ, RESP> toBuilder() =>
      new CommandStateBuilder<REQ, RESP>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandState &&
        status == other.status &&
        command == other.command &&
        result == other.result &&
        progress == other.progress;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, status.hashCode), command.hashCode), result.hashCode),
        progress.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('CommandState')
          ..add('status', status)
          ..add('command', command)
          ..add('result', result)
          ..add('progress', progress))
        .toString();
  }
}

class CommandStateBuilder<REQ, RESP>
    implements
        Builder<CommandState<REQ, RESP>, CommandStateBuilder<REQ, RESP>> {
  _$CommandState<REQ, RESP> _$v;

  CommandStatus _status;
  CommandStatus get status => _$this._status;
  set status(CommandStatus status) => _$this._status = status;

  CommandBuilder<REQ> _command;
  CommandBuilder<REQ> get command => _$this._command;
  set command(CommandBuilder<REQ> command) => _$this._command = command;

  CommandResultBuilder<RESP> _result;
  CommandResultBuilder<RESP> get result => _$this._result;
  set result(CommandResultBuilder<RESP> result) => _$this._result = result;

  CommandProgressBuilder _progress;
  CommandProgressBuilder get progress => _$this._progress;
  set progress(CommandProgressBuilder progress) => _$this._progress = progress;

  CommandStateBuilder();

  CommandStateBuilder<REQ, RESP> get _$this {
    if (_$v != null) {
      _status = _$v.status;
      _command = _$v.command?.toBuilder();
      _result = _$v.result?.toBuilder();
      _progress = _$v.progress?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandState<REQ, RESP> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$CommandState<REQ, RESP>;
  }

  @override
  void update(void updates(CommandStateBuilder<REQ, RESP> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$CommandState<REQ, RESP> build() {
    _$CommandState<REQ, RESP> _$result;
    try {
      _$result = _$v ??
          new _$CommandState<REQ, RESP>._(
              status: status,
              command: _command?.build(),
              result: _result?.build(),
              progress: _progress?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'command';
        _command?.build();
        _$failedField = 'result';
        _result?.build();
        _$failedField = 'progress';
        _progress?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'CommandState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
