import 'package:flutter/foundation.dart';
import 'package:umvvm/umvvm.dart';

/// Main class to extend to create interactor
/// Interactors contain business logic for given state type
/// Interactors can contain dependencies and receive events
/// They also can contain parts
/// You also can execute requests and cancel them automatically when interactor will be disposed
/// with [executeAndCancelOnDispose] method
///
/// Example:
///
/// ```dart
/// @basicInstance
/// class TestInteractor extends BaseInteractor<int, String> {
///   @override
///   int get initialState => 1;
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

    initializeDependencies();
    initializeStatefullInstance();

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
    await initializeDependenciesAsync();
  }

  @mustCallSuper
  @override
  void initializeWithoutConnections(Input? input) {
    super.initializeWithoutConnections(input);

    initializeStore();

    initialized = true;
  }

  @mustCallSuper
  @override
  Future<void> initializeWithoutConnectionsAsync(Input? input) async {
    initialized = true;
  }
}
