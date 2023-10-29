import 'dart:async';

import 'package:umvvm/umvvm.dart';

class ObservableChange<T> {
  final T? next;
  final T? previous;

  ObservableChange(
    this.next,
    this.previous,
  );
}

/// Base class for observable object
///
/// You can get [stream] of object changes and also [update] object data
///
/// Example:
/// ```dart
/// void example() {
///   final userName = Observable<String>.initial("Ted");
///
///   final subscription = userName.stream.listen((name) {
///     // do something with name
///   });
///
///   userName.update('John');
///
///   print('current userName=${userName.current}');
///
///   subscription.cancel();
///   userName.dispose();
/// }
/// ```
class Observable<T> {
  late StreamController<ObservableChange<T>> _controller;
  T? _current;

  /// Flag indicating that this observable is disposed
  /// Observable bus can't be used if this flag is true 
  bool _isDisposed = false;

  /// Flag indicating that this observable is disposed
  /// Observable bus can't be used if this flag is true 
  bool get isDisposed => _isDisposed;

  Observable() {
    _controller = StreamController<ObservableChange<T>>.broadcast();
  }

  Observable.initial(T initial) {
    _controller = StreamController<ObservableChange<T>>.broadcast();

    update(initial);
  }

  /// Current value of observable object
  T? get current => _current;

  /// Broadcast stream of [current] changes
  Stream<ObservableChange<T>> get stream =>
      _controller.stream.asBroadcastStream();

  /// Updates [current] and [previous]
  void update(T data) {
    if (_isDisposed) {
      throw IllegalStateException(
        message: 'Can\'t update observable after dispose.',
      );
    }

    final change = ObservableChange(data, _current);
    _current = data;

    if (!_controller.isClosed) {
      _controller.add(change);
    }
  }

  /// Closes underlaying stream controller
  void dispose() {
        if (_isDisposed) {
      throw IllegalStateException(
        message: 'Can\'t call dispose if observable is already disposed.',
      );
    }

    _controller.close();

    _isDisposed = true;
  }
}
