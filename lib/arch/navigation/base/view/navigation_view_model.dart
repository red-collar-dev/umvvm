import 'package:flutter/widgets.dart';
import 'package:umvvm/umvvm.dart';

abstract class NavigationViewModel<Widget extends StatefulWidget, State>
    extends BaseViewModel<Widget, State> {
  dynamic screenTab;

  late final navigationInteractor = UMvvmApp.navigationInteractor!;

  void pop() {
    if (navigationInteractor.isInGlobalStack()) {
      navigationInteractor.pop();
    } else if (screenTab == null) {
      navigationInteractor.pop();
    } else {
      navigationInteractor.popInTab(screenTab!);
    }
  }
}

abstract class NavigationView<View extends StatefulWidget, ScreenState,
        ViewModel extends NavigationViewModel<View, ScreenState>>
    extends BaseView<View, ScreenState, ViewModel> {
  dynamic screenTab;

  @mustCallSuper
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final currentNavigatorKey = Navigator.of(context).widget.key;

      if (currentNavigatorKey !=
              viewModel.navigationInteractor.globalNavigatorKey &&
          currentNavigatorKey !=
              viewModel.navigationInteractor.bottomSheetDialogNavigatorKey) {
        viewModel.screenTab = viewModel.navigationInteractor.currentTab;
      } else {
        viewModel.screenTab = null;
      }
    } catch (e) {
      // ignore - just no navigator - always using global navigation in this case
    }
  }
}
