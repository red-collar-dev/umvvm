// coverage:ignore-file

/// Annotate class as custom mvvm instance
/// ```dart
/// @Instance(inputType: String, singleton: true)
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
///
class Instance {
  /// Input type for this instance. Map<String, dynamic> by default
  final Type inputType;

  /// Flag indicating is this instance singleton - defaults to false
  final bool singleton;

  /// Flag indicating is this instance lazy singleton - defaults to false.
  /// Only matters if [singleton] is set to true
  final bool lazy;

  /// Initialization order for this instance.
  /// Only matters if [singleton], [async]
  /// and [awaitInitialization] are set to true
  final int? initializationOrder;

  /// Flag indicating that initialization of
  /// this instance needs to be awaited at app startup - defaults to false
  /// Only matters if [singleton], [async] are set to true
  final bool awaitInitialization;

  /// Flag indicating that this instance is async - has async initialization
  final bool async;

  /// Flag indicating that this instance is [BaseInstancePart]
  final bool part;

  const Instance({
    this.inputType = Map<String, dynamic>,
    this.singleton = false,
    this.lazy = false,
    this.initializationOrder,
    this.async = false,
    this.awaitInitialization = false,
    this.part = false,
  });
}

/// Annotate class as default mvvm instance
/// ```dart
/// @instance
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const basicInstance = Instance();

/// Annotate class as mvvm instance part
/// ```dart
/// @instancePart
/// class NavigationPart extends BaseInstancePart<int, NavigationInteractor> {
/// ```
const instancePart = Instance(part: true);

/// Annotate class as async mvvm instance part
/// ```dart
/// @asyncInstancePart
/// class NavigationPart extends BaseInstancePart<int, NavigationInteractor> {
/// ```
const asyncInstancePart = Instance(part: true, async: true);

/// Annotate class as singleton mvvm instance
/// ```dart
/// @singleton
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const singleton = Instance(singleton: true);

/// Annotate class as lazy singleton mvvm instance
/// ```dart
/// @lazySingleton
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const lazySingleton = Instance(singleton: true, lazy: true);

/// Annotate class as async default mvvm instance
/// ```dart
/// @instance
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const asyncBasicInstance = Instance(async: true);

/// Annotate class as async singleton mvvm instance
/// ```dart
/// @singleton
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const asyncSingleton = Instance(singleton: true, async: true);

/// Annotate class as async lazy singleton mvvm instance
/// ```dart
/// @lazySingleton
/// class NavigationWrapper extends BaseWrapper<NavigationStack, Map<String, dynamic>> {
///   @override
///   NavigationStack provideInstance(Map<String, dynamic>? input) {
///     return NavigationStack();
///   }
/// }
/// ```
const asyncLazySingleton = Instance(singleton: true, lazy: true, async: true);
