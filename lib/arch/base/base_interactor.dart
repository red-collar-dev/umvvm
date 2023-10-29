import 'package:flutter/foundation.dart';
import 'package:umvvm/umvvm.dart';

/// Main class to extend to create interactor
/// Interactors contain business logic for given state type
///  ```dart
/// @basicInstance
/// class TestInteractor extends BaseInteractor<int, String> {
///   @override
///   int initialState(String? input) => 1;
/// }
/// ```
abstract class BaseInteractor<State, Input> extends MvvmInstance<Input?>
    with
        StatefulMvvmInstance<State, Input?>,
        DependentMvvmInstance<Input?>,
        ApiCaller<Input?> {
  @mustCallSuper
  @override
  void initialize(Input? input) {
    super.initialize(input);

    initializeStore(initialState(input));

    initializeDependencies(input);

    if (syncRestore) {
      restoreCachedStateSync();
    } else {
      restoreCachedStateAsync();
    }

    initialized = true;
  }

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();

    disposeStore();
    disposeDependencies();
    cancelAllRequests();

    initialized = false;
  }

  @mustCallSuper
  @override
  Future<void> initializeAsync(Input? input) async {
    await super.initializeAsync(input);
    await initializeDependenciesAsync(input);
  }

  @mustCallSuper
  @override
  void initializeWithoutConnections(Input? input) {
    initializeStore(initialState(input));
    initializeDependenciesWithoutConnections(input);

    initialized = true;
  }

  @mustCallSuper
  @override
  Future<void> initializeWithoutConnectionsAsync(Input? input) async {
    initializeStore(initialState(input));
    
    await initializeDependenciesWithoutConnectionsAsync(input);

    initialized = true;
  }

  bool get syncRestore => true;
}
