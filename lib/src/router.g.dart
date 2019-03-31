// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<RouteProps> _$routePropsSerializer = new _$RoutePropsSerializer();
Serializer<RouteCommand> _$routeCommandSerializer =
    new _$RouteCommandSerializer();
Serializer<RouteResult> _$routeResultSerializer = new _$RouteResultSerializer();

class _$RoutePropsSerializer implements StructuredSerializer<RouteProps> {
  @override
  final Iterable<Type> types = const [RouteProps, _$RouteProps];
  @override
  final String wireName = 'modux/RouteProps';

  @override
  Iterable serialize(Serializers serializers, RouteProps object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'inflating',
      serializers.serialize(object.inflating,
          specifiedType: const FullType(bool)),
      'replaceRoute',
      serializers.serialize(object.replaceRoute,
          specifiedType: const FullType(bool)),
      'fullscreen',
      serializers.serialize(object.fullscreen,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  RouteProps deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RoutePropsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'inflating':
          result.inflating = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'replaceRoute':
          result.replaceRoute = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'fullscreen':
          result.fullscreen = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
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
      'state',
      serializers.serialize(object.state, specifiedType: parameterT),
      'props',
      serializers.serialize(object.props,
          specifiedType: const FullType(RouteProps)),
    ];

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
        case 'state':
          result.state =
              serializers.deserialize(value, specifiedType: parameterT);
          break;
        case 'props':
          result.props.replace(serializers.deserialize(value,
              specifiedType: const FullType(RouteProps)) as RouteProps);
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

class _$RouteProps extends RouteProps {
  @override
  final bool inflating;
  @override
  final bool replaceRoute;
  @override
  final bool fullscreen;

  factory _$RouteProps([void updates(RoutePropsBuilder b)]) =>
      (new RoutePropsBuilder()..update(updates)).build();

  _$RouteProps._({this.inflating, this.replaceRoute, this.fullscreen})
      : super._() {
    if (inflating == null) {
      throw new BuiltValueNullFieldError('RouteProps', 'inflating');
    }
    if (replaceRoute == null) {
      throw new BuiltValueNullFieldError('RouteProps', 'replaceRoute');
    }
    if (fullscreen == null) {
      throw new BuiltValueNullFieldError('RouteProps', 'fullscreen');
    }
  }

  @override
  RouteProps rebuild(void updates(RoutePropsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  RoutePropsBuilder toBuilder() => new RoutePropsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RouteProps &&
        inflating == other.inflating &&
        replaceRoute == other.replaceRoute &&
        fullscreen == other.fullscreen;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, inflating.hashCode), replaceRoute.hashCode),
        fullscreen.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RouteProps')
          ..add('inflating', inflating)
          ..add('replaceRoute', replaceRoute)
          ..add('fullscreen', fullscreen))
        .toString();
  }
}

class RoutePropsBuilder implements Builder<RouteProps, RoutePropsBuilder> {
  _$RouteProps _$v;

  bool _inflating;
  bool get inflating => _$this._inflating;
  set inflating(bool inflating) => _$this._inflating = inflating;

  bool _replaceRoute;
  bool get replaceRoute => _$this._replaceRoute;
  set replaceRoute(bool replaceRoute) => _$this._replaceRoute = replaceRoute;

  bool _fullscreen;
  bool get fullscreen => _$this._fullscreen;
  set fullscreen(bool fullscreen) => _$this._fullscreen = fullscreen;

  RoutePropsBuilder();

  RoutePropsBuilder get _$this {
    if (_$v != null) {
      _inflating = _$v.inflating;
      _replaceRoute = _$v.replaceRoute;
      _fullscreen = _$v.fullscreen;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RouteProps other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RouteProps;
  }

  @override
  void update(void updates(RoutePropsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$RouteProps build() {
    final _$result = _$v ??
        new _$RouteProps._(
            inflating: inflating,
            replaceRoute: replaceRoute,
            fullscreen: fullscreen);
    replace(_$result);
    return _$result;
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
  final T state;
  @override
  final RouteProps props;

  factory _$RouteCommand([void updates(RouteCommandBuilder<T> b)]) =>
      (new RouteCommandBuilder<T>()..update(updates)).build();

  _$RouteCommand._({this.name, this.from, this.to, this.state, this.props})
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
    if (state == null) {
      throw new BuiltValueNullFieldError('RouteCommand', 'state');
    }
    if (props == null) {
      throw new BuiltValueNullFieldError('RouteCommand', 'props');
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
        state == other.state &&
        props == other.props;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc($jc(0, name.hashCode), from.hashCode), to.hashCode),
            state.hashCode),
        props.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RouteCommand')
          ..add('name', name)
          ..add('from', from)
          ..add('to', to)
          ..add('state', state)
          ..add('props', props))
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

  T _state;
  T get state => _$this._state;
  set state(T state) => _$this._state = state;

  RoutePropsBuilder _props;
  RoutePropsBuilder get props => _$this._props ??= new RoutePropsBuilder();
  set props(RoutePropsBuilder props) => _$this._props = props;

  RouteCommandBuilder();

  RouteCommandBuilder<T> get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _from = _$v.from;
      _to = _$v.to;
      _state = _$v.state;
      _props = _$v.props?.toBuilder();
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
    _$RouteCommand<T> _$result;
    try {
      _$result = _$v ??
          new _$RouteCommand<T>._(
              name: name,
              from: from,
              to: to,
              state: state,
              props: props.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'props';
        props.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'RouteCommand', _$failedField, e.toString());
      }
      rethrow;
    }
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
