# UMVVM library

![Tests code coverage status](coverage/coverage_badge.svg)

Set of classes for Flutter app architecture

To generage test coverage report run sh coverage.sh

## Data Layer

Data layer consists of <b>Api</b> and <b>Box</b> classes.

Api class contains getters or functions that return <b>HttpRequest</b>.
Api classes must be annotated with <b>api</b> annotation.

<b>HttpRequest</b> has following fields:

```dart
this.method = RequestMethod.get,
this.url,
this.parser,
this.file,
this.query,
this.timeout = const Duration(seconds: 20),
this.headers = const {},
this.body,
this.baseUrl,
this.requiresLogin = true,
this.databaseGetDelegate,
this.databasePutDelegate,
this.simulateResponse,
this.simulateResult,
this.formData,
this.ignoreCancelations = false,
this.onPrefetchFromDatabase,
this.additionalInterceptors = const [],
```

Important notes here:

1) <b>parser</b> is a function that takes server response body and headers
2) <b>simulateResponse</b> lets you simulate unparsed server response body and headers so you can check parser function and database delegates
3) <b>simulateResult</b> lets you simulate parsed server response, so you can check interactors and viewmodels

Typical example for Api class would be:

```dart
@api
class PostsApi {
  HttpRequest<List<Post>> getPosts(int offset, int limit) => HttpRequest<List<Post>>()
    ..method = RequestMethod.get
    ..baseUrl = getBaseUrl(BackendUrls.main)
    ..url = '/posts'
    ..parser = (result, headers) async {
      final list = <Post>[];

      result?.forEach((data) {
        list.add(Post.fromJson(data));
      });

      return list;
    };
}
```

Typical example of Api mocks for tests:

```dart
class MockPostsApiResponse extends PostsApi {
  @override
  HttpRequest<List<Post>> getPosts(int offset, int limit) => super.getPosts(offset, limit)
    ..simulateResponse = SimulateResponse(
      data: '[{"id": 1, "title": "qwerty", "body": "qwerty" }]',
    );
}

class MockPostsApiResult extends PostsApi {
  @override
  HttpRequest<List<Post>> getPosts(int offset, int limit) => HttpRequest<List<Post>>()
    ..simulateResult = Response(code: 200, result: [
      Post(
        title: '',
        body: '',
        id: 1,
      )
    ]);
}
```

If project requires database we can use any database such as <b>ObjectBox</b> or <b>Hive</b> or <b>Isar</b> library and add delegates to <b>HttpRequest</b> if needed.

Here is an example:

```dart
HttpRequest<List<Post>> getPosts(int offset, int limit) => HttpRequest<List<Post>>()
    ..method = RequestMethod.get
    ..baseUrl = getBaseUrl(BackendUrls.main)
    ..url = '/posts'
    ..parser = (result, headers) async {
        final list = <Post>[];

        result?.forEach((data) {
        list.add(Post.fromJson(data));
        });

        return list;
    }
    ..databaseGetDelegate = ((headers) => PostsBox.getPostsDelegate(offset, limit, headers))
    ..databasePutDelegate = ((result) => PostsBox.putPostsDelegate(result));
```

Where delegates looks like:

```dart
class PostsBox {
  static Future<List<Post>> getPostsDelegate(int offset, int limit, Map? headers) async {
    final postsBox = App.objectBox.store.box<Post>();

    final query = postsBox.query().build();

    query
      ..offset = offset
      ..limit = limit;

    final List<Post> posts = query.find();

    return posts;
  }

  static Future putPostsDelegate(List<Post> result) async {
    final postsBox = App.objectBox.store.box<Post>();

    postsBox.putMany(result);
  }
}
```

Delegates are defined in a separate file as static functions.

After you initialized all request fields you can use it as follows:

```dart
Future<void> loadPosts(int offset, int limit, {bool refresh = false}) async {
    updateState(state.copyWith(posts: LoadingData()));

    late Response<List<Post>> response;

    if (refresh) {
      response = await Apis.posts.getPosts(0, limit).execute();
    } else {
      response = await Apis.posts.getPosts(offset, limit).execute();
    }

    if (response.isSuccessful || response.isSuccessfulFromDatabase) {
      updateState(state.copyWith(posts: ResultData(response.result ?? [])));
    } else {
      updateState(state.copyWith(posts: ErrorData(response.error)));
    }
}
```

To process errors and retry requests override onError method

Using instance of <b>requestsCollection</b> you can cancel all current requests and retry all of them

Here is an example:

```dart
class HttpRequest<T> extends RequestImplementation<T> {
  @override
  Map<String, dynamic> get defaultHeaders => {};

  @override
  String get defaultBaseUrl => Flavor.dev.baseUrl;

  @override
  int get defaultTimeoutInSeconds => AppSettings.defaultRequestTimeoutInSeconds;

  @override
  void logPrint(Object obj) {
    LogUtility.printMessage(obj.toString());
  }

  @override
  void exceptionPrint(Object error, StackTrace trace) {
    LogUtility.e(error, trace);
  }

  @override
  void onAuthorization(Dio dio) {
    if (!requiresLogin) {
      return;
    }

    final token = app.instances
        .get<AuthorizationInteractor>()
        .state
        .token;

    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  @override
  Future onError(DioException error, RetryHandler retry) async {
    if (error.type == DioExceptionType.cancel) {
      return error;
    }

    if (error.response?.statusCode == 401) {
      final authorizationInteractor =
          app.instances.get<AuthorizationInteractor>();

      await requestCollection.cancelAllRequests(
        retryRequestsAfterProcessing: true,
        cancelReasonProcessor: () async {
          await authorizationInteractor.requestNewToken(reAuth: true);
        },
      );

      if (!authorizationInteractor.isAuthorized) {
        return error;
      }

      return retry();
    }

    return error;
  }
}
```

View models interactors and wrappers cancels all running requests when they are disposed
To enable this behaviour run requests with <b>executeRequest</b> method

```dart
response = await executeRequest(app.apis.posts.getPosts(0, limit));
```

## DI

Library contains simple DI container

You can access it with <b>app.instances</b>

DI container can hold any MvvmInstance child class

There are two ways to annotate mvvm instances to use in di container <b>singleton</b> and <b>basicInstance</b>
Or you can also use full <b>Instance</b> annotation

Singleton instances belong to global scope

There are several predefined scopes - global, unique and weak

Global scope holds singleton instances
Weak scope holds objects that can be accessed from anywhere as long as some mvvm instance connected to it
Unique scope always create new instance

You can define your own scopes

If you annotate class as <b>lazySingleton</b> it will be created only when accessed first time

Here are some examples:

```dart
@Instance(inputType: String)
class StringWrapper extends BaseWrapper<String, String> {
  @override
  String provideInstance(String? input) {
    return '';
  }
}

```

or basic instance wrapper:

```dart
@basicInstance
class StringWrapper extends BaseWrapper<String, Map<String, dynamic>> {
  @override
  String provideInstance(Map<String, dynamic>? input) {
    return '';
  }
}

```

or singleton wrapper:

```dart
@singleton
class StringWrapper extends BaseWrapper<String, Map<String, dynamic>> {
  @override
  String provideInstance(Map<String, dynamic>? input) {
    return '';
  }
}

```

or lazy singleton wrapper:

```dart
@lazySingleton
class StringWrapper extends BaseWrapper<String, Map<String, dynamic>> {
  @override
  String provideInstance(Map<String, dynamic>? input) {
    return '';
  }
}

```

Two specify scope that you want object from you can pass scope param to <b>get</b> method

```dart
app.instances
  .get<NavigationInteractor>(scope: CustomScopes.userProfileScope('1'));
```

You can also specify scope in connector objects that discussed below

```dart
@override
List<Connector> dependsOn(OtherUserProfileView input) => [
      app.connectors.userInteractorConnector(
        scope: CustomScopes.userProfileScope(input.user?.id ?? ''),
        input: UserInteractorInput(username: input.user?.username),
      ),
    ];
```

Then you can get instance with <b>getLocalInstance</b> method

### Async initialization

If you want to create instance that is initialized asynchronously you can pass <b>async</b> param to <b>Instance</b> annotation
Or you can use predefined default annotations

You must mark instances as async if they depend on other async instances

Then you can get async instances with <b>getAsync</b> method

Here are some examples:

```dart
@asyncLazySingleton
class StringWrapper extends AsyncBaseWrapper<String, Map<String, dynamic>> {
  @override
  Future<String> provideInstance(Map<String, dynamic>? input) async {
    return '';
  }
}

```

```dart
@asyncSingleton
class StringWrapper extends AsyncBaseWrapper<String, Map<String, dynamic>> {
  @override
  Future<String> provideInstance(Map<String, dynamic>? input) async {
    return '';
  }
}

```

```dart
@asyncBasicInstance
class StringWrapper extends AsyncBaseWrapper<String, Map<String, dynamic>> {
  @override
  Future<String> provideInstance(Map<String, dynamic>? input) async {
    return '';
  }
}

```

```dart
@Instance(async: true, initializationOrder: 1)
class StringWrapper extends AsyncBaseWrapper<String, Map<String, dynamic>> {
  @override
  Future<String> provideInstance(Map<String, dynamic>? input) async {
    return '';
  }
}

```

In last example there is also <b>initializationOrder</b> field that is used to specify the order of singleton initialization

You also need to specify <b>isAsync</b> flag for async instance

You can also implement <b>initializeAsync</b> method for async instances

Here is example of async instance:

```dart
@asyncSingleton
class UserDefaultsInteractor extends BaseInteractor<UserDefaultsState, Map<String, dynamic>> {
  @override
  UserDefaultsState initialState(Map<String, dynamic>? input) => UserDefaultsState();

  @override
  bool isAsync(Map<String, dynamic>? input) => true;

  @override
  Future<void> initializeAsync(T input) async {
    // ...
  }

  @override
  Future<void> dispose() async {
    // ...
  }
}

```

You dont need to override <b>isAsync</b> flag if you use async dependencies, this is done automatically

Async instances also have method to handle dependency ready status

You can also specify if app needs to await instance initialization with <b>awaitInitialization</b> flag

```dart
@asyncSingleton
class UserDefaultsInteractor extends BaseInteractor<UserDefaultsState, Map<String, dynamic>> {
  @override
  UserDefaultsState initialState(Map<String, dynamic>? input) => UserDefaultsState();

  @override
  bool isAsync(Map<String, dynamic>? input) => true;

  @override
  Future<void> initializeAsync(T input) async {
    // ...
  }

  @override
  Future<void> dispose() async {
    // ...
  }

  @override
  void onAsyncInstanceReady(Type type, {int? index}) {
    switch (type) {
      case value:
        
        break;
      default:
    }
  }
}
```

You can unregister instances with <b>app.instances.unregisterInstance</b> method

### Modules

Modules are simple classes that helps orginize dependencies

If your class depend on similar set of scoped instances you can combine them using <b>InstanceModule</b>.

Here is an example

```dart
class TestModule extends InstancesModule {
  @override
  List<Connector> get dependencies => [
        app.connectors.postInteractorConnector(),
        app.connectors.postsInteractorConnector(),
      ];

  @override
  String get id => 'test';
}

class Modules {
  static final test = TestModule();
}

@singleton
class StringWrapper extends BaseHolderWrapper<String, Map<String, dynamic>?> {
  @override
  String provideInstance(Map<String, dynamic>? input) {
    return '';
  }

  @override
  List<InstancesModule> belongsToModules(Map<String, dynamic>? input) => [
    Modules.test,
  ];
}
```

You also can enable runtime check for cyclic dependencies with <b>instances.checkForCyclicDependencies</b> flag

## Business Logic Layer

This layer contains <b>Interactor</b> and <b>Wrapper</b> classes.

### Interactors

Interactors contain state and subscription to <b>EventBus</b> events (EventBus will be described later). 

You can also specify input type for this interactor

State can be updated with <b>updateState</b> method and receivers like view models can later subscribe to state update events with <b>updates</b> or <b>changes</b>.

Interactors must be annotated with <b>basicInstance</b> or <b>singleton</b>.

When interactor is annotated with <b>singleton</b> it belongs to global interactors collection.

We dont need to write dependencies in our view models for singleton interactors (view model dependencies will be explained below) 
and we can access it with <b>app.instances</b>.

When interactor is annotated with <b>basicInstance</b> we need to write dependency for it in our view model (view model dependencies will be explained below).

This interactors can be disposed when dependent element is disposed.

Interactors also can depend on other interactors and wrappers via <b>dependsOn</b> override

They are connected with <b>Connector</b> objects that will be discussed below

Typical example would be:

```dart
@basicInstance
class PostsInteractor extends BaseInteractor<PostsState, Map<String, dynamic>> with LikePostMixin {
  @override
  List<Connector> dependsOn(String? input) => [
        Connector(type: SupportInteractor, unique: true),
        Connector(type: ReactionsWrapper),
      ];

  Future<void> loadPosts(int offset, int limit, {bool refresh = false}) async {
    updateState(state.copyWith(posts: LoadingData()));

    late Response<List<Post>> response;

    if (refresh) {
      response = await app.apis.posts.getPosts(0, limit).execute();
    } else {
      response = await app.apis.posts.getPosts(offset, limit).execute();
    }

    if (response.isSuccessful || response.isSuccessfulFromDatabase) {
      updateState(state.copyWith(posts: ResultData(response.result ?? [])));
    } else {
      updateState(state.copyWith(posts: ErrorData(response.error)));
    }
  }

  void _onPostLiked(int id) {
    final posts = (state.posts as ResultData<List<Post>>).result.toList();
    final index = posts.indexWhere((element) => element.id == id);

    if (index == -1) {
      return;
    }

    posts[index] = posts[index].copyWith(isLiked: !posts[index].isLiked);

    updateState(state.copyWith(posts: ResultData(posts)));
  }

  @override
  PostsState initialState(Map<String, dynamic>? input) => PostsState();

  @override
  List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>((event) {
        _onPostLiked(event.id);
      }),
    ];
}
```

Or singleton interactor:

```dart
@singleton
class UserDefaultsInteractor extends BaseInteractor<UserDefaultsState, Map<String, dynamic>> {
  @override
  void onRestore(Map<String, dynamic> savedStateObject) {
    updateState(UserDefaultsState.fromJson(savedStateObject));
  }

  void saveFirstAppLaunch() {
    updateState(state.copyWith(firstAppLaunch: true));
  }

  @override
  UserDefaultsState initialState(Map<String, dynamic>? input) => UserDefaultsState();
  
  @override
  Map<String, dynamic> get savedStateObject => state.toJson();

  @override
  bool get isRestores => true;
  
  @override
  List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>((event) {
        _onPostLiked(event.id);
      }),
    ];
}

```

In the last example we also can see that every interactor also has <b>savedStateObject</b>.

When we override <b>savedStateObject</b> so interactor can save state to <b>SharedPreferences</b> or other provider

It later can be restored with <b>onRestore</b>. It also has <b>isRestores</b> flag - that is false by default.

By default state key in saved object is equals to state runtime type, but you can override it with <b>stateId</b> getter

You can also specify input type for every interactor in annotation:

```dart
@Instance(inputType: String)
class UserDefaultsInteractor extends BaseInteractor<UserDefaultsState, String> {
  @override
  void onRestore(Map<String, dynamic> savedStateObject) {
    updateState(UserDefaultsState.fromJson(savedStateObject));
  }

  void saveFirstAppLaunch() {
    updateState(state.copyWith(firstAppLaunch: true));
  }

  @override
  UserDefaultsState initialState(String? input) => UserDefaultsState();
  
  @override
  Map<String, dynamic> get savedStateObject => state.toJson();

  @override
  bool get isRestores => true;
  
  @override
  List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>((event) {
        _onPostLiked(event.id);
      }),
    ];
}

```

### Wrappers

Wrappers contain logic for working this third party dependencies
Wrapper can be just used as instance holders or contain logic for working with third party api

If wrapper holds object instance extend <b>BaseHolderWrapper</b>, overwise use <b>BaseWrapper</b>

Wrappers also can be singleton or default

Wrappers unlike interactors don`t have state, but they also can receive <b>EventBus</b> events (EventBus will be described later). 

Typical example would be:

```dart
@singleton
class StripeWrapper extends BaseWrapper<String> {
}
```

or singleton wrapper:

```t
@singleton
class StringWrapper extends BaseHolderWrapper<String, Map<String, dynamic>> {
  @override
  String provideInstance(Map<String, dynamic>? input) {
    return '';
  }
}

```

Instances can be then obtained using <b>app.instances.get<T>()</b>

### Parts

To split logic in large instances you can create <b>parts</b>

Part is instance type that has reference to parent mvvm instance

Part can receive events and can't have separate state or dependencies

Here is an example:

```dart
@instancePart
class TestInteractorPart extends BaseInstancePart<PostsInteractor> {
  void testUpdate() {
    parentInstance.updateState(parentInstance.state.copyWith(
      active: false,
    ));
  }

  @override
  Future<void> initializeAsync(T input) async {
    // ...
  }

  @override
  Future<void> dispose() async {
    // ...
  }

  @override
  void onAsyncPartReady(Type type, {int? index}) {
    switch (type) {
      case value:
        
        break;
      default:
    }
  }
}

@basicInstance
class PostsInteractor extends BaseInteractor<PostsState, Map<String, dynamic>?>
    with LikePostMixin {
  @override
  List<Type> parts(Map<String, dynamic>? input) => [
        TestInteractorPart,
      ];

  late final testPart = useInstancePart<TestInteractorPart>();
}
```

### Connectors

Connectors are objects that describe dependency for interactor or wrapper

We can specify a type of object(interactor or wrapper) we want to depend on.

We can also specify if we want to get unique instance or shared instance

We also can define count of objects that we want to connect

We also can specify scope of object

If you mark connector as lazy instance will be connected when addressed first time
with <b>getLazyLocalInstance</b> and <b>getAsyncLazyLocalInstance</b>

We can also specify if we want to connect object without dependencies - 
in this case connected object won't be listening <b>EventBus</b> events and objects that this instance depends on also won't be connected
It is usefull if you just want to use some method of small instance

Examples would be:

```dart
@override
List<Connector> dependsOn(Map<String, dynamic>? input) => [
      Connector(type: SupportInteractor, scope: BaseScopes.unique), // unique instance
      Connector(type: ShareInteractor, count: 5), // 5 unique instances
      Connector(type: ReactionsWrapper), // shared instance
      // instance without connections, only works for unique instances
      Connector(type: ReactionsWrapper, withoutConnections: true, scope: BaseScopes.unique),
      Connector(type: ReactionsWrapper, scope: CustomScopes.test), // scoped instance
      Connector(type: ReactionsWrapper, scope: CustomScopes.test, lazy: true), // lazy scoped instance
    ];
```

Library creates connectors for every single wrapper and interactor 
This way you dont need to write <b>Connector</b> classes for every interactor and just use predefined ones as follows:

```dart
@override
List<Connector> dependsOn(PostView input) => [
      app.connectors.postInteractorConnector(
        unique: true,
        input: input.post,
      ),
    ];
```

### EventBus

View models, interactors and wrappers have access to <b>EventBus</b> events.
Events can be subscribed to with <b>subscribe</b> method.

An example:

```dart
@override
List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>((event) {
        _onPostLiked(event.id);
      }),
    ];
```

To send events you need to access <b>EventBus</b> instance.

An example:

```dart
app.eventBus.send(PostLikedEvent(id: id));
```

You also can create separate instance of EventBus to handle specific operation - for example file uploading
While we upload file we may want to send progress events in separate event bus

```dart
final fileUploadEventBus = EventBus.newSeparateInstance();
```

Reactions to events for every mvvm instance can be paused and resuming with corresponding methods
By default events do not react to pauses
To enable this you can subscribe to events with follows:

```dart
@override
List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>(
        (event) {
          _onPostLiked(event.id);
        },
        reactsToPause: true,
        // flag indicating if instance need to 'replay' events that was received while instance was paused
        firesAfterResume: false,
      ),
    ];
```

Views by default pause view models when view become invisible

### MainApp and Apis

There are also utility classes to connect all components of architecture.
This classes are generated using <b>builder</b> package.

Main app class contains instances of interactor collection and wrapper locator

For example here is definition of main app class:

```dart
@mainApp
class App extends UMvvmApp with AppGen {
  late SharedPreferences prefs;
  late ObjectBox objectBox;
  final apis = Apis();

  @override
  Future<void> initialize() async {
    await super.initialize();
  }
}
```

And here is definition of Apis class:


```dart
@mainApi
class Apis with ApisGen {}
```

App class holds instances to global <b>InstanceCollection</b>, <b>SharedPreferences</b>, <b>Apis</b> and <b>ObjectBox</b>(if needed) and whatever you define
We define global variable for app class and initialize it before calling <b>runApp</b>.

## Presentation Layer

Presentation layer consists of view model and view classes that are connected together.

### ViewModel

View models contain logic for view classes

It also contains local map of instances, and local state that we like <b>Interactor</b> can update with <b>updateState</b>.
We also can listen to state changes with <b>updatesFor</b> or <b>changesFor</b>
We add interactors and wrappers to view model using <b>dependsOn</b> method.
Using this method we can connect default interactors to view model.
View models like interactors and wrappers can receive <b>EventBus</b> events using <b>subscribe</b> method.

To get local instances connected to view model use <b>getLocalInstance</b>

View models also can override <b>onLaunch</b> method that is called on first frame of corresponding view.

```dart
class PostsListViewModel extends BaseViewModel<PostsListView, PostsListViewState> {
  @override
  List<Connector> dependsOn(PostsListView widget) => [
        Connector(interactor: PostsInteractor),
        Connector(interactor: PostInteractor, unique: true),
        Connector(type: ReactionsWrapper),
      ]; 

  @override
  void onLaunch(PostsListView widget) {
    // called with initState
    getLocalInstance<PostsInteractor>().loadPosts(0, 30);
  }

  @override
  void onFirstFrame(SearchView widget) {
    // called with first frame - post frame callback
  }

  @override
  void onRestore(Map<String, dynamic> savedStateObject) {
    updateState(HomeViewState.fromJson(savedStateObject));
  }

  void like(int id) {
    getLocalInstance<PostsInteractor>().likePost(id);
  }

  void openPost(Post post) {
    app.navigation.routeTo(Routes.post, payload: {
      'post': post,
    });
  }

  Stream<StatefulData<List<Post>>?> get postsStream => getLocalInstance<PostsInteractor>().updates((state) => state.posts);

  @override
  PostsListViewState get initialState => PostsListViewState();

  @override
  Map<String, dynamic> get savedStateObject => state.toJson();

  @override
  List<EventBusSubscriber> subscribe() => [
      on<PostLikedEvent>((event) {
        _onPostLiked(event.id);
      }),
    ];
}
```

View models also have <b>savedStateObject</b> and it also later can be restored with <b>onRestore</b>.

To split logic in large view model you can also create <b>parts</b> for this view model

### View

The last class is view. View has a reference to view model and getter for initial state for view model.
If you need to pass test view model extend <b>BaseWidget</b> instead of <b>StatefulWidget</b>

Example: 

```dart
class PostsListView extends BaseWidget {
  const PostsListView({
    super.key,
    super.viewModel,
  });

  @override
  State<StatefulWidget> createState() {
    return _PostsListViewWidgetState();
  }
}

class _PostsListViewWidgetState extends BaseView<PostsListView, PostsListViewState, PostsListViewModel> {
  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 232, 232),
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: StreamBuilder<StatefulData<List<Post>>?>(
        stream: viewModel.postsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return buildList(snapshot.data!);
          }

          return Container();
        },
      ),
    );
  }

  Widget buildList(StatefulData<List<Post>> data) {
    return data.when(
      result: (List<Post> value) {
        return ListView.builder(
          itemBuilder: (context, index) {
            final item = value[index];

            return PostCard(
              onTap: () {
                viewModel.openPost(item);
              },
              onLikeTap: () {
                viewModel.like(item.id ?? 1);
              },
              title: item.title ?? '',
              body: item.body ?? '',
              isLiked: item.isLiked,
            );
          },
          itemCount: value.length,
        );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (dynamic message) {
        return Text(message.toString());
      },
    );
  }

  @override
  PostsListViewModel createViewModel() {
    return PostsListViewModel();
  }
}
```

You can pass mocked view model view <b>viewModel</b> input parameter of <b>BaseWidget</b>

## Navigation

Package also contains default way to handle navigation

To use this feature you need to subclass <b>BaseNavigationInteractor</b>

Or you can mark class with <b>AppNavigation</b> annotation

If your app contains tab navigation than NavigationInteractor will look like this:

```dart
@singleton
@AppNavigation(tabs: AppTab)
class NavigationInteractor
     extends NavigationInteractorDeclaration<NavigationState> {

  @override
  AppTab? get currentTab => state.currentTab;

  @override
  Map<AppTab, GlobalKey<NavigatorState>> get currentTabKeys => {
        AppTabs.posts: GlobalKey<NavigatorState>(),
        AppTabs.likedPosts: GlobalKey<NavigatorState>(),
      };

  @override
  NavigationInteractorSettings get settings => NavigationInteractorSettings(
        initialRoute: RouteNames.home,
        tabs: AppTabs.tabs,
        tabViewHomeRoute: RouteNames.home,
        initialTabRoutes: {
          AppTabs.posts: RouteNames.posts,
          AppTabs.likedPosts: RouteNames.likedPosts,
        },
        appContainsTabNavigation: true,
      );

  @override
  Future<void> onBottomSheetOpened(Widget child, UIRouteSettings route) async {
    // ignore
  }

  @override
  Future<void> onDialogOpened(Widget child, UIRouteSettings route) async {
    // ignore
  }

  @override
  Future<void> onRouteOpened(Widget child, UIRouteSettings route) async {
    if (route.global) {
      app.eventBus.send(GlobalRoutePushedEvent(replace: route.replace));
    }
  }

  @override
  void setCurrentTab(AppTab tab) {
    updateState(state.copyWith(currentTab: tab));
  }

  @override
  NavigationState initialState(Map<String, dynamic>? input) => NavigationState(
        currentTab: AppTabs.posts,
      );
}
```

If app does not contains tab navigation than you can skip tab related methods:

```dart
@singleton
@AppNavigation()
class NavigationInteractor
     extends NavigationInteractorDeclaration<NavigationState> {

  @override
  AppTab? get currentTab => state.currentTab;

  @override
  NavigationInteractorSettings get settings => NavigationInteractorSettings(
        initialRoute: RouteNames.home,
      );

  @override
  Future<void> onBottomSheetOpened(Widget child, UIRouteSettings route) async {
    unawaited(analyticsWrapper.logScreenView(
      child.runtimeType.toString(),
      route.name ?? '',
    ));
  }

  @override
  Future<void> onDialogOpened(Widget child, UIRouteSettings route) async {
    unawaited(analyticsWrapper.logScreenView(
      child.runtimeType.toString(),
      route.name ?? '',
    ));
  }

  @override
  Future<void> onRouteOpened(Widget child, UIRouteSettings route) async {
    unawaited(analyticsWrapper.logScreenView(
      child.runtimeType.toString(),
      route.name ?? '',
    ));

    if (route.global) {
      app.eventBus.send(GlobalRoutePushedEvent(replace: route.replace));
    }
  }

  @override
  List<EventBusSubscriber> subscribe() => [
      ];

  @override
  NavigationState initialState(Map<String, dynamic>? input) =>
      NavigationState();
}
```

Last flag that describes navigation flow in app is <b>bottomSheetsAndDialogsUsingSameNavigator</b>

If this flag is false than you need to create separate navigator for bottom sheets and dialogs - usefull if you have some overlay views for app

You also need to specify navigation interactor in main app annotation

```dart
@MainApp(navigationInteractorType: NavigationInteractor)
class App extends UMvvmApp<NavigationInteractor> with AppGen {
}
```

You also need to initialize default values

```dart
UINavigationSettings.transitionDuration = kAnimationDuration;
UINavigationSettings.barrierColor = UIColors.surfaceDarkSemitransparent;
UINavigationSettings.bottomSheetBorderRadius = BorderRadius.only(
  topLeft: UIDimentions.defaultWidgetBorderRadius.topLeft,
  topRight: UIDimentions.defaultWidgetBorderRadius.topRight,
);
```

If you need to specify custom transition builder you can specify <b>routeBuilder</b> in navigation settings object 
or you can specify <b>customRouteBuilder</b> for specific route

You can see how routes are specified in <b>example_navigation</b> example

And here is also list of methods in <b>BaseNavigationInteractor</b>

```dart
bool isInGlobalStack({bool includeBottomSheetsAndDialogs = true});

void pop({
  dynamic payload,
  bool onlyInternalStack = false,
});

void popInTab(
  AppTabType tab, {
  dynamic payload,
  bool onlyInternalStack = false,
});

Future<void> routeTo(
  UIRoute<RouteType> routeData, {
  bool? fullScreenDialog,
  bool replace = false,
  bool replacePrevious = false,
  bool? uniqueInStack,
  bool? forceGlobal,
  bool? needToEnsureClose,
  bool? dismissable,
  Object? id,
});

Future<dynamic> showDialog(
  UIRoute<DialogType> dialog, {
  bool? forceGlobal,
  bool? dismissable,
  bool? uniqueInStack,
  Object? id,
});

Future<dynamic> showBottomSheet(
  UIRoute<BottomSheetType> bottomSheet, {
  bool? forceGlobal,
  bool? dismissable,
  bool? uniqueInStack,
  Object? id,
});

void setCurrentTab(AppTabType tab);
bool canPop({bool global = true});
void popGlobalToFirst();
void popInTabToFirst(AppTabType appTab, {bool clearStack = true});
void popToTab(AppTabType tab);
void popAllNavigatiorsToFirst();
void popAllDialogsAndBottomSheets();
void popUntil(Object routeName, {bool forceGlobal = false});
void popGlobalUntil(Object routeName);
void popInTabUntil(Object routeName);
void popAllTabsToFirst();
bool containsGlobalRoute(Object routeName);
```

To complete navigation initialization you also need to provide root views for global and tab navigation(if present)

For global navigation there are <b>GlobalNavigationRootViewModel</b> and <b>GlobalNavigationRootView</b>

For tab navigation there are <b>TabNavigationRootViewModel</b> and <b>TabNavigationRootView</b>

It is also recommended to use <b>NavigationViewModel</b> and <b>NavigationView</b> as base classes for your views and view models
since it ensures that navigation is handled in correct navigation scope (tab or global)

Examples how to use it is also in <b>example_navigation</b> example

### Deep links

Navigation supports deeplinks with <b>BaseDeepLinksInteractor</b>

Then you need to specify it in <b>AppNavigation</b> annotation <b>deepLinks</b> argiments

You need to provide methods to get initial link and get stream of deep links
To respond to deep links define routes with <b>@Link</b> annotation
Example for this will be in next section

Here is example of deep links interactor

```dart
class TestDeepLinksInteractor extends BaseDeepLinksInteractor<int> {
  bool defaultLinkHandlerCalled = false;

  final linkStreamController = StreamController<String>.broadcast();

  @override
  Future<void> defaultLinkHandler() async {
    defaultLinkHandlerCalled = true;
  }

  @override
  Future<String> getInitialLink() async {
    return 'test';
  }

  @override
  int initialState(Map<String, dynamic>? input) => 1;

  @override
  Stream<String> linkStream() {
    return linkStreamController.stream;
  }

  @override
  void dispose() {
    super.dispose();

    linkStreamController.close();
  }
}
```

### Defining routes and deep links

To define routes you need to specify 3 classes - <b>Routes</b>, <b>Dialogs</b> and <b>BottomSheets</b>

Routes can respond to links with <b>@Link</b> annotation
By defining link you can specify link filters for specific screen

Here is an examples of possible links

```dart
class TestMapper extends LinkMapper {
  @override
  UIRoute constructRoute(
    Map<String, String> pathParams,
    Map<String, String> queryParams,
  ) {
    return UIRoute<RouteNames>(
      name: RouteNames.postsRegex,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @override
  (Map<String, String>, Map<String, String>) mapParamsFromUrl(String url) {
    return (
      {
        'testParam': 'qwerty',
      },
      {},
    );
  }

  @override
  Future<void> openRoute(UIRoute route) async {
    await app.navigation.routeTo(route as UIRoute<RouteNames>);
  }
}

class TestHandler extends LinkHandler {
  @override
  Future<UIRoute?> parseLinkToRoute(String url) async {
    return UIRoute(
      name: 'test',
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @override
  Future<void> processRoute(UIRoute? route) async {}
}

@routes
class Routes extends RoutesBase with RoutesGen {
  @Link(
    paths: ['posts/:{id}'],
    query: [
      'filter',
    ],
  )
  UIRoute<RouteNames> post({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.post,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: [
      'posts/:{id}/:{type}',
      'posts/:{id}/test/test',
    ],
    query: [
      'filter=qwerty1|qwerty2',
    ],
    customHandler: TestHandler,
  )
  UIRoute<RouteNames> postCustom({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postCustom,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: [
      'posts/:{id}',
    ],
    query: [
      'filter=qwerty1|qwerty2',
    ],
  )
  UIRoute<RouteNames> postFilterMultiplePossibleValues({
    int? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postFilterMultiplePossibleValues,
      defaultSettings: UIRouteSettings(
        global: pathParams != null,
      ),
      child: Container(),
    );
  }

  @Link(
    paths: [
      'posts/:{id}',
    ],
    query: [
      'filter=qwerty1|qwerty2',
    ],
    possibleFragments: [
      'state',
    ],
  )
  UIRoute<RouteNames> postFilterMultiplePossibleValuesWithAnchor({
    int? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postFilterMultiplePossibleValuesWithAnchor,
      defaultSettings: UIRouteSettings(
        global: pathParams != null,
      ),
      child: Container(),
    );
  }

  @Link(
    paths: ['posts/:{id}'],
    query: [
      'filter=[qwerty1,qwerty2]',
    ],
  )
  UIRoute<RouteNames> postArray({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postArray,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['posts/:{id}'],
    query: [
      'filter=qwerty',
    ],
  )
  UIRoute<RouteNames> post2({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.post2,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['posts/:{id}'],
    query: ['filter', 'query?'],
  )
  UIRoute<RouteNames> post3({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.post3,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['posts/:{id}/test'],
    query: ['filter', 'query?'],
  )
  UIRoute<RouteNames> post4({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.post4,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['posts'],
  )
  UIRoute<RouteNames> posts({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.posts,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(paths: ['posts'], query: [
    'filter',
  ])
  UIRoute<RouteNames> posts2({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.posts2,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(paths: ['stub'], query: [
    'filter',
  ])
  UIRoute<RouteNames> stub({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.stub,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['home'],
  )
  UIRoute<RouteNames> home({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.home,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['likedPosts'],
  )
  UIRoute<RouteNames> likedPosts({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.likedPosts,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    regexes: ['(.*?)'],
    customParamsMapper: TestMapper,
  )
  UIRoute<RouteNames> postsRegex({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postsRegex,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['*/posts/:{id}'],
  )
  UIRoute<RouteNames> postsWithPrefix({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postsWithPrefix,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    paths: ['*/posts/test/:{id}'],
  )
  UIRoute<RouteNames> postsWithAnchor({
    String? state,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: RouteNames.postsWithAnchor,
      defaultSettings: const UIRouteSettings(),
      child: Container(),
    );
  }
}
```

You can also execute link yourself with <b>openLink</b> method of <b>NavigationInteractor</b>

Parameters from link will be available in <b>pathParams</b> and <b>queryParams</b>

If you need to access url fragment add <b>String? state</b> to function declaration

Construction of link is up to developer

## Utility

Package contains small utility classes

The first two are just sealed classes for network requests and field validation:

```dart
sealed class StatefulData<T> {
  T unwrap() {
    return (this as ResultData<T>).result;
  }

  const StatefulData();
}

class LoadingData<T> extends StatefulData<T> {
  const LoadingData();
}

class ResultData<T> extends StatefulData<T> {
  final T result;

  const ResultData({
    required this.result,
  });
}

class ErrorData<T> extends StatefulData<T> {
  final dynamic error;

  const ErrorData({this.error});
}
```

Stateful data can be unwrapped to get result value if it is present

```dart
sealed class FieldValidationState {}

class ValidFieldState extends FieldValidationState {}

class IgnoredFieldState extends FieldValidationState {}

class ErrorFieldState extends FieldValidationState {
  final String? error;

  ErrorFieldState({this.error});
}
```

There is also <b>ResultState</b> class to hold function execution result

There are also two helper mixins that you can apply to your view models

First is <b>UseDisposableMixin</b>

It provides methods to initialize disposable objects like <b>TextEditingController</b>
They will be disposed authomatically

Here is full list of supported initializers:

```dart
TextEditingController useTextEditingController({String? text});
ScrollController useScrollController();
Debouncer useDebouncer({required Duration delay});
CancellationToken useCancelToken();
```

Here is usecase example:

```dart
class SupportViewModel
    extends NavigationViewModel<SupportView, SupportViewState>
    with UseDisposableViewModelMixin {
  late final descriptionController = useTextEditingController();
  late final emailController = useTextEditingController();
}
```

Using this method to initialize disposable objects you dont need to actually dispose them - it will be done automatically

Second usefull mixin is <b>FormViewModelMixin</b>

It helps to manage form views where you need to validate user input

Here you can see the example:

```dart
class SupportViewModel
    extends NavigationViewModel<SupportView, SupportViewState>
    with FormViewModelMixin, UseDisposableViewModelMixin {
  late final descriptionController = useTextEditingController();
  late final emailController = useTextEditingController();

  final descriptionKey = GlobalKey();
  final emailKey = GlobalKey();

  @override
  Future<void> submit() async {
    await sendSupportRequest();
  }

  @override
  ValidatorsMap get validators => {
        descriptionKey: () {
          return Future.value(validateSupportTicket(descriptionController));
        },
        emailKey: () {
          return Future.value(validateEmail(emailController, []));
        }
      };

  @override
  SupportViewState initialState(SupportView input) => SupportViewState();
}
```

Using this mixin gives you 2 methods:

Firstly you can call <b>executeSubmitAction</b> method to handle form validation
Secondly you can use streams of validation states for fields that you specified


```dart
WhatHappenedField(
  key: viewModel.descriptionKey,
  controller: viewModel.descriptionController,
  stateStream:
      viewModel.fieldStateStream(viewModel.descriptionKey),
  initialState: () =>
      viewModel.currentFieldState(viewModel.descriptionKey),
  validator: () =>
      viewModel.validatorForKey(viewModel.descriptionKey),
),

Button(
  onTap: () async {
    await viewModel.executeSubmitAction();
  },
);

```

## Tests

There are several helper methods for tests

Before tests you need set test mode flag

```dart
UMvvmApp.isInTestMode = true;
```

Also you need to register instances if they are used in test

```dart
setUp(() async {
  UMvvmApp.isInTestMode = true;

  app.registerInstances();
  await app.createSingletons();
});
```

Mock instances can be registered with instance collection

```dart
app.instances.addTest<PostInteractor>(BaseScopes.global, postInteractor);
```

Test view models can be passed as params to mvvm widgets:

```dart
final widget = PostView(
  post: Post(
    title: 'TestTitle',
    body: 'TestBody',
    id: 1,
  ),
  viewModel: MockViewModel(),
);
```

To check that event was sent and received you can use following methods:

```dart
app.eventBus.checkEventWasSent(EnsureCloseRequestedEvent);

postInteractor.checkEventWasReceived(EnsureCloseRequestedEvent);
```

Important note:

If you using VSCode then to quickly generate files for this architecture use [UMvvm-Gen VSCode extension](https://gitlab.rdclr.ru/flutter/umvvm-vs-code-gen-plugin/)

