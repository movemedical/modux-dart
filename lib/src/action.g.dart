// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Nothing> _$nothingSerializer = new _$NothingSerializer();
Serializer<Value> _$valueSerializer = new _$ValueSerializer();

class _$NothingSerializer implements StructuredSerializer<Nothing> {
  @override
  final Iterable<Type> types = const [Nothing, _$Nothing];
  @override
  final String wireName = 'modux/src/Nothing';

  @override
  Iterable serialize(Serializers serializers, Nothing object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object>[];
  }

  @override
  Nothing deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new NothingBuilder().build();
  }
}

class _$ValueSerializer implements StructuredSerializer<Value> {
  @override
  final Iterable<Type> types = const [Value, _$Value];
  @override
  final String wireName = 'modux/src/Value';

  @override
  Iterable serialize(Serializers serializers, Value object,
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
  Value deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new ValueBuilder<Object>()
        : serializers.newBuilder(specifiedType) as ValueBuilder;

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

class _$Nothing extends Nothing {
  factory _$Nothing([void updates(NothingBuilder b)]) =>
      (new NothingBuilder()..update(updates)).build();

  _$Nothing._() : super._();

  @override
  Nothing rebuild(void updates(NothingBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  NothingBuilder toBuilder() => new NothingBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Nothing;
  }

  @override
  int get hashCode {
    return 766531449;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper('Nothing').toString();
  }
}

class NothingBuilder implements Builder<Nothing, NothingBuilder> {
  _$Nothing _$v;

  NothingBuilder();

  @override
  void replace(Nothing other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Nothing;
  }

  @override
  void update(void updates(NothingBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Nothing build() {
    final _$result = _$v ?? new _$Nothing._();
    replace(_$result);
    return _$result;
  }
}

class _$Value<T> extends Value<T> {
  @override
  final T value;

  factory _$Value([void updates(ValueBuilder<T> b)]) =>
      (new ValueBuilder<T>()..update(updates)).build();

  _$Value._({this.value}) : super._() {
    if (value == null) {
      throw new BuiltValueNullFieldError('Value', 'value');
    }
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('Value', 'T');
    }
  }

  @override
  Value<T> rebuild(void updates(ValueBuilder<T> b)) =>
      (toBuilder()..update(updates)).build();

  @override
  ValueBuilder<T> toBuilder() => new ValueBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Value && value == other.value;
  }

  @override
  int get hashCode {
    return $jf($jc(0, value.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Value')..add('value', value))
        .toString();
  }
}

class ValueBuilder<T> implements Builder<Value<T>, ValueBuilder<T>> {
  _$Value<T> _$v;

  T _value;
  T get value => _$this._value;
  set value(T value) => _$this._value = value;

  ValueBuilder();

  ValueBuilder<T> get _$this {
    if (_$v != null) {
      _value = _$v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Value<T> other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Value<T>;
  }

  @override
  void update(void updates(ValueBuilder<T> b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Value<T> build() {
    final _$result = _$v ?? new _$Value<T>._(value: value);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
