// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RouteCommandAction _$wirePush = const RouteCommandAction._('push');
const RouteCommandAction _$wirePopAndPush =
    const RouteCommandAction._('popAndPush');
const RouteCommandAction _$wireReplace = const RouteCommandAction._('replace');

RouteCommandAction _$routeActionKindValueOf(String name) {
  switch (name) {
    case 'push':
      return _$wirePush;
    case 'popAndPush':
      return _$wirePopAndPush;
    case 'replace':
      return _$wireReplace;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<RouteCommandAction> _$routeCommandActionValues =
    new BuiltSet<RouteCommandAction>(const <RouteCommandAction>[
  _$wirePush,
  _$wirePopAndPush,
  _$wireReplace,
]);

const RouteType _$wirePage = const RouteType._('page');
const RouteType _$wireDialog = const RouteType._('dialog');
const RouteType _$wireFullscreen = const RouteType._('fullscreen');
const RouteType _$wireBottomSheet = const RouteType._('bottomSheet');

RouteType _$routeTypeValueOf(String name) {
  switch (name) {
    case 'page':
      return _$wirePage;
    case 'dialog':
      return _$wireDialog;
    case 'fullscreen':
      return _$wireFullscreen;
    case 'bottomSheet':
      return _$wireBottomSheet;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<RouteType> _$routeTypeValues =
    new BuiltSet<RouteType>(const <RouteType>[
  _$wirePage,
  _$wireDialog,
  _$wireFullscreen,
  _$wireBottomSheet,
]);

Serializer<RouteCommandAction> _$routeCommandActionSerializer =
    new _$RouteCommandActionSerializer();
Serializer<RouteType> _$routeTypeSerializer = new _$RouteTypeSerializer();
Serializer<RouteCommand> _$routeCommandSerializer =
    new _$RouteCommandSerializer();
Serializer<RouteResult> _$routeResultSerializer = new _$RouteResultSerializer();

class _$RouteCommandActionSerializer
    implements PrimitiveSerializer<RouteCommandAction> {
  @override
  final Iterable<Type> types = const <Type>[RouteCommandAction];
  @override
  final String wireName = 'modux/RouteCommandAction';

  @override
  Object serialize(Serializers serializers, RouteCommandAction object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  RouteCommandAction deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RouteCommandAction.valueOf(serialized as String);
}

class _$RouteTypeSerializer implements PrimitiveSerializer<RouteType> {
  @override
  final Iterable<Type> types = const <Type>[RouteType];
  @override
  final String wireName = 'modux/RouteType';

  @override
  Object serialize(Serializers serializers, RouteType object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  RouteType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RouteType.valueOf(serialized as String);
}

class _$RouteCommandSerializer implements StructuredSerializer<RouteCommand> {
  @override
  final Iterable<Type> types = const [RouteCommand, _$RouteCommand];
  @override
  final String wireName = 'modux/RouteCommand';

  @override
  Iterable serialize(Serializers serializers, RouteCommand object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'from',
      serializers.serialize(object.from, specifiedType: const FullType(String)),
      'to',
      serializers.serialize(object.to, specifiedType: const FullType(String)),
    ];
    if (object.action != null) {
      result
        ..add('action')
        ..add(serializers.serialize(object.action,
            specifiedType: const FullType(RouteCommandAction)));
    }
    if (object.routeType != null) {
      result
        ..add('routeType')
        ..add(serializers.serialize(object.routeType,
            specifiedType: const FullType(RouteType)));
    }
    if (object.replaceName != null) {
      result
        ..add('replaceName')
        ..add(serializers.serialize(object.replaceName,
            specifiedType: const FullType(String)));
    }
    if (object.state != null) {
      result
        ..add('state')
        ..add(serializers.serialize(object.state, specifiedType: parameterT));
    }
    if (object.inflating != null) {
      result
        ..add('inflating')
        ..add(serializers.serialize(object.inflating,
            specifiedType: const FullType(bool)));
    }

    return result;
  }

  @override
  RouteCommand deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new RouteCommandBuilder<Object>()
        : serializers.newBuilder(specifiedType) as RouteCommandBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'from':
          result.from = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'to':
          result.to = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'action':
          result.action = serializers.deserialize(value,
                  specifiedType: const FullType(RouteCommandAction))
              as RouteCommandAction;
          break;
        case 'routeType':
          result.routeType = serializers.deserialize(value,
              specifiedType: const FullType(RouteType)) as RouteType;
          break;
        case 'replaceName':
          result.replaceName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'state':
          result.state =
              serializers.deserialize(value, specifiedType: parameterT);
          break;
        case 'inflating':
          result.inflating = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$RouteResultSerializer implements StructuredSerializer<RouteResult> {
  @override
  final Iterable<Type> types = const [RouteResult, _$RouteResult];
  @override
  final String wireName = 'modux/RouteResult';

  @override
  Iterable serialize(Serializers serializers, RouteResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'value',
      serializers.serialize(object.value, specifiedType: parameterT),
    ];

    return result;
  }

  @override
  RouteResult deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new RouteResultBuilder<Object>()
        : serializers.newBuilder(specifiedType) as RouteResultBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'value':
          result.value =
              serializers.deserialize(value, specifiedType: parameterT);
          break;
      }
    }

    return result.build();
  }
}

class _$RouteCommand<T> extends RouteCommand<T> {
  @override
  final String name;
  @override
  final String from;
  @override
  final String to;
  @override
  final RouteCommandAction action;
  @override
  final RouteType routeType;
  @override
  final String replaceName;
  @override
  final T state;
  @override
  final bool inflating;

  factory _$RouteCommand([void updates(RouteCommandBuilder<T> b)]) =>
      (new RouteCommandBuilder<T>()..update(updates)).build();

  _$RouteCommand._(
      {this.name,
      this.from,
      this.to,
      this.action,
      this.routeType,
      this.replaceName,
      this.state,
      this.inflating})
      : super._() {
    if (name == null) {
      throw new BuiltValueNullFieldError('RouteCommand', 'name');
    }
    if (from == null) {
      throw new BuiltValueNullFieldError('RouteCommand', 'from');
    }
    if (to == null) {
      throw new BuiltValueNullFieldError('RouteCommand', 'to');
    }
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('RouteCommand', 'T');
    }
  }

  @override
  RouteCommand<T> rebuild(void updates(RouteCommandBuilder<T> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  RouteCommandBuilder<T> toBuilder() =>
      new RouteCommandBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RouteCommand &&
        name == other.name &&
        from == other.from &&
        to == other.to &&
        action == other.action &&
        routeType == other.routeType &&
        replaceName == other.replaceName &&
        state == other.state &&
        inflating == other.inflating;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, name.hashCode), from.hashCode),
                            to.hashCode),
                        action.hashCode),
                    routeType.hashCode),
                replaceName.hashCode),
            state.hashCode),
        inflating.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RouteCommand')
          ..add('name', name)
          ..add('from', from)
          ..add('to', to)
          ..add('action', action)
          ..add('routeType', routeType)
          ..add('replaceName', replaceName)
          ..add('state', state)
          ..add('inflating', inflating))
        .toString();
  }
}

class RouteCommandBuilder<T>
    implements Builder<RouteCommand<T>, RouteCommandBuilder<T>> {
  _$RouteCommand<T> _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _from;
  String get from => _$this._from;
  set from(String from) => _$this._from = from;

  String _to;
  String get to => _$this._to;
  set to(String to) => _$this._to = to;

  RouteCommandAction _action;
  RouteCommandAction get action => _$this._action;
  set action(RouteCommandAction action) => _$this._action = action;

  RouteType _routeType;
  RouteType get routeType => _$this._routeType;
  set routeType(RouteType routeType) => _$this._routeType = routeType;

  String _replaceName;
  String get replaceName => _$this._replaceName;
  set replaceName(String replaceName) => _$this._replaceName = replaceName;

  T _state;
  T get state => _$this._state;
  set state(T state) => _$this._state = state;

  bool _inflating;
  bool get inflating => _$this._inflating;
  set inflating(bool inflating) => _$this._inflating = inflating;

  RouteCommandBuilder();

  RouteCommandBuilder<T> get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _from = _$v.from;
      _to = _$v.to;
      _action = _$v.action;
      _routeType = _$v.routeType;
      _replaceName = _$v.replaceName;
      _state = _$v.state;
      _inflating = _$v.inflating;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RouteCommand<T> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RouteCommand<T>;
  }

  @override
  void update(void updates(RouteCommandBuilder<T> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$RouteCommand<T> build() {
    final _$result = _$v ??
        new _$RouteCommand<T>._(
            name: name,
            from: from,
            to: to,
            action: action,
            routeType: routeType,
            replaceName: replaceName,
            state: state,
            inflating: inflating);
    replace(_$result);
    return _$result;
  }
}

class _$RouteResult<T> extends RouteResult<T> {
  @override
  final T value;

  factory _$RouteResult([void updates(RouteResultBuilder<T> b)]) =>
      (new RouteResultBuilder<T>()..update(updates)).build();

  _$RouteResult._({this.value}) : super._() {
    if (value == null) {
      throw new BuiltValueNullFieldError('RouteResult', 'value');
    }
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('RouteResult', 'T');
    }
  }

  @override
  RouteResult<T> rebuild(void updates(RouteResultBuilder<T> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  RouteResultBuilder<T> toBuilder() =>
      new RouteResultBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RouteResult && value == other.value;
  }

  @override
  int get hashCode {
    return $jf($jc(0, value.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RouteResult')..add('value', value))
        .toString();
  }
}

class RouteResultBuilder<T>
    implements Builder<RouteResult<T>, RouteResultBuilder<T>> {
  _$RouteResult<T> _$v;

  T _value;
  T get value => _$this._value;
  set value(T value) => _$this._value = value;

  RouteResultBuilder();

  RouteResultBuilder<T> get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RouteResult<T> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RouteResult<T>;
  }

  @override
  void update(void updates(RouteResultBuilder<T> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$RouteResult<T> build() {
    final _$result = _$v ?? new _$RouteResult<T>._(value: value);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
