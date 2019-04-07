// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Empty> _$emptySerializer = new _$EmptySerializer();
Serializer<Value> _$valueSerializer = new _$ValueSerializer();

class _$EmptySerializer implements StructuredSerializer<Empty> {
  @override
  final Iterable<Type> types = const [Empty, _$Empty];
  @override
  final String wireName = 'modux/src/Empty';

  @override
  Iterable serialize(Serializers serializers, Empty object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object>[];
  }

  @override
  Empty deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new EmptyBuilder().build();
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

class _$Empty extends Empty {
  factory _$Empty([void updates(EmptyBuilder b)]) =>
      (new EmptyBuilder()..update(updates)).build();

  _$Empty._() : super._();

  @override
  Empty rebuild(void updates(EmptyBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  EmptyBuilder toBuilder() => new EmptyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Empty;
  }

  @override
  int get hashCode {
    return 634538651;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper('Empty').toString();
  }
}

class EmptyBuilder implements Builder<Empty, EmptyBuilder> {
  _$Empty _$v;

  EmptyBuilder();

  @override
  void replace(Empty other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Empty;
  }

  @override
  void update(void updates(EmptyBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Empty build() {
    final _$result = _$v ?? new _$Empty._();
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
