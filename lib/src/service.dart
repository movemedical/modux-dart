import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import 'action.dart';
import 'store.dart';

abstract class AbstractStoreService<Self>
    with StoreSubscriptionsMixin
    implements StoreService {
  AbstractStoreService(this.store);

  final Store store;

  @override
  Type get keyType => Self;

  @override
  void init() {}

  @override
  @mustCallSuper
  void dispose() {
    disposeSubscriptions();
  }
}

abstract class StatefulActionsService<
        State extends Built<State, StateBuilder>,
        StateBuilder extends Builder<State, StateBuilder>,
        Actions extends ModuxActions<State, StateBuilder, Actions>,
        Self extends StatefulActionsService<State, StateBuilder, Actions, Self>>
    extends AbstractStoreService<Self> {
  StatefulActionsService(Store store, this.actions) : super(store);

  final Actions actions;

  State get state => actions.$mapState(store.state);
}
