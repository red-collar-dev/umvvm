import 'package:test/test.dart';
import 'package:umvvm/umvvm.dart';

import '../helpers/test_builders.dart';
import '../mocks/test_interactors.dart';
import '../mocks/test_wrappers.dart';

class TestApp extends UMvvmApp {
  @override
  void registerInstances() {
    addTestBuilders(InstanceCollection.implementationInstance);
  }

  @override
  List<Connector> get singletonInstances => [
        const Connector(type: TestInteractor1),
        const Connector(type: TestInteractor3, async: true),
        const Connector(
          type: TestWrapper3,
          async: true,
          awaitInitialization: true,
          initializationOrder: 1,
        ),
        const Connector(
          type: TestWrapper4,
          initializationOrder: 2,
        ),
      ];
}

void main() {
  group('MvvmApp tests', () {
    late final app = TestApp();

    setUpAll(() async {
      UMvvmApp.isInTestMode = true;
    });

    test('MvvmApp initial test', () async {
      await app.initialize();

      expect(app.initialized, true);
      expect(app.eventBus, EventBus.instance);
      expect(app.instances.forceGet<TestInteractor3>().initialized, true);
      expect(app.instances.forceGet<TestWrapper3>().initialized, true);
      expect(app.instances.forceGet<TestWrapper4>().initialized, true);
    });
  });
}
