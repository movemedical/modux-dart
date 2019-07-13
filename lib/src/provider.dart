import 'store.dart';

class ModuxState {
  const ModuxState();
}

abstract class ModuxProvider<T> {
  T provide(Store store);
}
