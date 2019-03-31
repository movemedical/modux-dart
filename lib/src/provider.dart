import 'store.dart';

abstract class ModuxProvider<T> {
  T provide(Store store);
}
