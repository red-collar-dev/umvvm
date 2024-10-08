import 'package:flutter/material.dart';
import 'package:umvvm/umvvm.dart';
import 'package:sample_database/domain/data/app_tab.dart';
import 'package:sample_database/domain/global/global_app.dart';
import 'package:sample_database/domain/interactors/navigation/navigation_interactor.dart';

import 'home_view.dart';
import 'home_view_state.dart';

class HomeViewModel extends NavigationViewModel<HomeView, HomeViewState> {
  final Map<AppTab, GlobalKey<NavigatorState>> tabNavigatorKeys = {
    AppTabs.posts: GlobalKey<NavigatorState>(),
    AppTabs.likedPosts: GlobalKey<NavigatorState>(),
  };

  @override
  void onLaunch() {
    app.navigation.currentTabKeys = tabNavigatorKeys;
  }

  @override
  void onRestore(Map<String, dynamic> savedStateObject) {
    updateState(HomeViewState.fromJson(savedStateObject));
  }

  GlobalKey<NavigatorState> getNavigatorKey(AppTab tab) {
    return app.navigation.getNavigatorForTab(tab);
  }

  void changeTab(AppTab tab) {
    app.navigation.setCurrentTab(tab);
  }

  AppTab get initialTab => app.navigation.state.currentTab;

  Stream<AppTab?> get currentTabStream =>
      app.instances.get<NavigationInteractor>().updates((state) => state.currentTab);

  @override
  Map<String, dynamic> get savedStateObject => state.toJson();

  @override
  HomeViewState get initialState => HomeViewState();
}
