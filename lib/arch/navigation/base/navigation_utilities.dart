// coverage:ignore-file

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide DialogRoute, ModalBottomSheetRoute;
import 'package:umvvm/arch/navigation/settings.dart';
import 'package:umvvm/arch/navigation/utilities/bottom_sheet_route.dart';
import 'package:umvvm/arch/navigation/utilities/dialog_route.dart';
import 'package:umvvm/arch/navigation/utilities/willpop_cupertino_page_route.dart';

class NavigationUtilities {
  static Future<Object?>? pushDialogRoute({
    required GlobalKey<NavigatorState> navigator,
    required bool dismissable,
    required Widget child,
    required VoidCallback pop,
  }) =>
      navigator.currentState?.push(
        DialogRoute(
          barrierDismissible: dismissable,
          barrierColor: UINavigationSettings.barrierColor,
          transitionDuration: UINavigationSettings.transitionDuration,
          pageBuilder: (
            BuildContext buildContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return _overlayRouteContainer(
              dismissable: dismissable,
              child: child,
              pop: pop,
            );
          },
        ),
      );

  static Future? pushBottomSheetRoute({
    required GlobalKey<NavigatorState> navigator,
    required bool dismissable,
    required Widget child,
    required VoidCallback pop,
  }) =>
      navigator.currentState?.push(
        ModalBottomSheetRoute(
          builder: (BuildContext buildContext) {
            return _overlayRouteContainer(
              dismissable: dismissable,
              child: child,
              pop: pop,
            );
          },
          dismissible: dismissable,
          enableDrag: dismissable,
        ),
      );

  static PageRoute buildPageRoute(
    Widget child,
    bool fullScreenDialog,
    VoidCallback? onClosed,
    Future<void> Function()? onWillPop,
  ) {
    if (Platform.isAndroid) {
      return MaterialPageRoute(
        builder: (BuildContext context) => onClosed == null
            ? child
            : WillPopScope(
                onWillPop: () async {
                  if (onWillPop != null) {
                    await onWillPop();

                    return false;
                  }

                  onClosed(); // triggers only when used android system back button

                  return Future.value(true);
                },
                child: child,
              ),
        fullscreenDialog: fullScreenDialog,
      );
    } else {
      return UICupertinoPageRoute(
        builder: (BuildContext context) => onWillPop != null
            ? WillPopScope(
                onWillPop: () async {
                  await onWillPop();

                  return false;
                },
                child: child,
              )
            : child,
        fullscreenDialog: fullScreenDialog,
        onClosedCallback: onClosed, // triggers only when used ios back gesture
      );
    }
  }

  static Widget _overlayRouteContainer({
    required bool dismissable,
    required Widget child,
    required VoidCallback pop,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            if (dismissable) {
              pop();
            }
          },
          child: WillPopScope(
            onWillPop: () async {
              if (dismissable) {
                pop();
              }

              return false;
            },
            child: child,
          ),
        );
      },
    );
  }
}
