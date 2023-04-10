import 'dart:async';

import 'event_bus.dart';
import 'observable.dart';

typedef StateUpdater<State> = void Function(State state);
typedef StoreMapper<Value, State> = Value Function(State state);

typedef EventBusSubscriber = void Function(dynamic payload);

/// Class to hold store change
class StoreChange<Value> {
  final Value? previous;
  final Value next;

  StoreChange(
    this.previous,
    this.next,
  );
}

/// Store is providing access to [State] for current containing class and [EventBus]
class Store<State> {
  /// Observable for [State] that belongs to this store
  late Observable<State> _state;
  State get state => _state.current!;

  /// Main stream for all store values
  Stream<State> get stream => _state.stream.map((event) => event.next!);

  /// Updates current state
  /// Listeners of [stream] will be notified about changes
  ///
  /// ```dart
  /// Future<void> loadPosts(int offset, int limit, {bool refresh = false}) async {
  ///   updateState(state.copyWith(posts: StatefulData.loading()));
  ///
  ///   late Response<List<Post>> response;
  ///
  ///   if (refresh) {
  ///     response = await Apis.posts.getPosts(0, limit).execute();
  ///   } else {
  ///     response = await Apis.posts.getPosts(offset, limit).execute();
  ///   }
  ///
  ///   if (response.isSuccessful || response.isSuccessfulFromDatabase) {
  ///     updateState(state.copyWith(posts: StatefulData.result(response.result ?? [])));
  ///   } else {
  ///     updateState(state.copyWith(posts: StatefulData.error(response.error)));
  ///   }
  /// }
  /// ```
  void updateState(State update) {
    _state.update(update);
  }

  /// Initializes internal [Observable]
  void initialize(State state) {
    _state = Observable<State>.initial(state);
  }

  /// Disposes [Observable]
  void dispose() {
    _state.dispose();
  }

  /// Stream of new values in [state]
  /// Using mapper you can select values you want to listen
  ///
  /// ```dart
  /// Stream<StatefulData<List<Post>>?> get postsStream => interactors.get<PostsInteractor>().updates((state) => state.posts);
  /// ```
  Stream<Value> updates<Value>(StoreMapper<Value, State> mapper) {
    return _state.stream.where((element) {
      return mapper(element.previous ?? element.next!) != mapper(element.next!);
    }).map((event) => mapper(event.next!));
  }

  /// Stream of changes of values [state]
  /// Using mapper you can select values you want to listen
  /// In contrast to [updates] this stream returns pairs of values -
  /// new state and previous state, so you can easily compare them if needed
  ///
  /// ```dart
  /// Stream<StoreChange<StatefulData<List<Post>>?>> get postsChangesStream => interactors.get<PostsInteractor>().changes((state) => state.posts);
  /// ```
  Stream<StoreChange<Value>> changes<Value>(StoreMapper<Value, State> mapper) {
    return _state.stream.map((event) => StoreChange(mapper(event.previous ?? event.next!), mapper(event.next!)));
  }
}
