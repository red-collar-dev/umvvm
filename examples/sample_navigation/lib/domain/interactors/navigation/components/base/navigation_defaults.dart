import 'package:flutter/material.dart';
import 'package:sample_navigation/domain/data/app_tab.dart';
import 'package:sample_navigation/domain/interactors/navigation/components/route_model.dart';
import 'package:sample_navigation/domain/interactors/navigation/components/screens/routes.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();
final bottomSheetDialogNavigatorKey = GlobalKey<NavigatorState>();
final routeObserver = RouteObserver<ModalRoute<void>>();

/// Default stack for global navigator
List<RouteModel> defaultRouteStack() => [
      const RouteModel(
        name: Routes.home,
        dismissable: false,
      ),
    ];

/// Default stacks for every tab navigator
Map<AppTab, List<RouteModel>> defaultTabRouteStack() => {
      AppTabs.posts: [
        const RouteModel(
          name: Routes.posts,
          dismissable: false,
        ),
      ],
      AppTabs.likedPosts: [
        const RouteModel(
          name: Routes.likedPosts,
          dismissable: false,
        ),
      ],
    };

void resetTabsKeys() {
  // creating new ones
  final newMap = {
    AppTabs.posts: GlobalKey<NavigatorState>(),
    AppTabs.likedPosts: GlobalKey<NavigatorState>(),
  };

  tabNavigatorKeys
    ..clear()
    ..addAll(newMap);
}

/// Global keys for every tab navigator
final Map<AppTab, GlobalKey<NavigatorState>> tabNavigatorKeys = {
  AppTabs.posts: GlobalKey<NavigatorState>(),
  AppTabs.likedPosts: GlobalKey<NavigatorState>(),
};
