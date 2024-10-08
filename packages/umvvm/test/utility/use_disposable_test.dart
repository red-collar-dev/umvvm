// ignore_for_file: cascade_invocations, unnecessary_statements

import 'package:flutter/src/widgets/framework.dart';
import 'package:test/test.dart';
import 'package:umvvm/umvvm.dart';

import '../mocks/test_widget.dart';

class TestMvvmDisposableInstance extends BaseViewModel<StatefulWidget, int>
    with UseDisposableMixin {
  late final scrollController = useScrollController();
  late final textEditingController = useTextEditingController();
  late final debouncer = useDebouncer(
    delay: const Duration(milliseconds: 100),
  );

  @override
  int get initialState => 1;

  @override
  void onLaunch() {
    // ignore
  }
}

void main() {
  group('UseDisposable tests', () {
    setUp(() async {
      UMvvmApp.isInTestMode = true;
    });

    test('UseDisposable dispose test', () async {
      final viewModel = TestMvvmDisposableInstance();

      viewModel.initialize(const TestWidget());

      viewModel.debouncer;
      viewModel.textEditingController;
      viewModel.scrollController;

      viewModel.dispose();

      expect(viewModel.debouncer.isDisposed, true);

      expect(
        () => viewModel.textEditingController.text = 'qwerty',
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
