import 'action.dart';
import 'store.dart';

import 'dart:collection';

abstract class ModuxForm implements ReduxFormScope {}

class ReduxFormImpl extends ReduxFormScopeImpl implements ModuxForm {}

class ReduxFormScopeImpl implements ReduxFormScope {
  final _controls = LinkedHashMap<String, FormControl>();
  final _scopes = LinkedHashMap<dynamic, ReduxFormScope>();

  @override
  FormControl<T> control<T>(ModuxValue<T> action) {
    return _controls[action.$name] as FormControl<T>;
  }

  @override
  Iterable<FormControl> get controls => _controls.values;

  @override
  bool hasControl(ModuxValue action) => _controls.containsKey(action.$name);
}

abstract class ReduxFormScope {
  FormControl<T> control<T>(ModuxValue<T> action);

  bool hasControl(ModuxValue action);

  Iterable<FormControl> get controls;
}

abstract class FormControl<T> {
  ModuxValue<T> get action;

  String get name => action?.$name ?? '';

  bool get enabled;

  set enabled(bool value);

  bool get disabled => !enabled;
//
  bool get touched;

  bool get untouched;

  bool get pristine;

  bool get dirty;

  bool get valid;
//
  Map<String, dynamic> get errors;

  T get value;

  set value(T value);

  String get hint => '';

  set hint(String value) {}

  bool get hasFocus;

  set focus(bool value);

  Future<bool> validate();
}

class FormControlImpl<T> extends FormControl<T> {
  final ModuxValue<T> action;
  bool _focused = false;
  bool _enabled = false;
  T _value = null;
  Map<String, dynamic> _errors;
  bool _validating = false;
  bool _touched = false;
  bool _dirty = false;
  bool _valid = false;

  FormControlImpl(this.action);

  @override
  Future<bool> validate() async {
    return true;
  }

  @override
  set focus(bool value) {
    _focused = value;
  }

  @override
  bool get hasFocus => _focused;

  @override
  T get value => _value;

  @override
  set value(T value) {
    _value = value;
  }

  bool get isValidating => _validating;

  @override
  Map<String, dynamic> get errors => _errors;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) {
    _enabled = value;
  }

  @override
  bool get valid => _valid;

  @override
  bool get dirty => _dirty;

  @override
  bool get pristine => !_dirty;

  @override
  bool get touched => _touched;

  @override
  bool get untouched => !_touched;
}
