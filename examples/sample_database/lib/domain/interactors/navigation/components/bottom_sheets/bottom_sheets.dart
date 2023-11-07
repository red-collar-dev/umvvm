import 'package:flutter/material.dart';
import 'package:umvvm/umvvm.dart';
import 'package:sample_database/domain/data/post.dart';
import 'package:sample_database/domain/global/global_store.dart';

part 'bottom_sheets.navigation.dart';

class TestHandler extends LinkHandler {
  @override
  Future<String> generateLinkForRoute() async {
    return 'testlink';
  }

  @override
  Future<UIRoute> parseLinkToRoute(String url) async {
    return UIRoute(
      name: 'test',
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @override
  Future<void> processRoute(UIRoute route) async {}
}

@bottomSheets
class BottomSheets extends RoutesBase with BottomSheetsGen {
  @Link(
    path: 'posts/:{id}',
    query: [
      'filter',
    ],
  )
  UIRoute<BottomSheetNames> post({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.post,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'posts/:{id}/:{type}',
    query: [
      'filter=qwerty1|qwerty2',
    ],
    customHandler: TestHandler,
  )
  UIRoute<BottomSheetNames> postCustom({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.post,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'posts/:{id}',
    query: [
      'filter=qwerty',
    ],
  )
  UIRoute<BottomSheetNames> post2({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.post,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'posts/:{id}',
    query: ['filter', 'query?'],
  )
  UIRoute<BottomSheetNames> post3({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.post,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'posts/:{id}/test',
    query: ['filter', 'query?'],
  )
  UIRoute<BottomSheetNames> post4({
    Post? post,
    int? id,
    int? filter,
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.post,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'posts',
  )
  UIRoute<BottomSheetNames> posts({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.posts,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(path: 'posts', query: [
    'filter',
  ])
  UIRoute<BottomSheetNames> posts2({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.posts,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(path: 'stub', query: [
    'filter',
  ])
  UIRoute<BottomSheetNames> stub({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.stub,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'home',
  )
  UIRoute<BottomSheetNames> home({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.home,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }

  @Link(
    path: 'likedPosts',
  )
  UIRoute<BottomSheetNames> likedPosts({
    Map<String, dynamic>? pathParams,
    Map<String, dynamic>? queryParams,
  }) {
    return UIRoute(
      name: BottomSheetNames.likedPosts,
      defaultSettings: const UIBottomSheetRouteSettings(),
      child: Container(),
    );
  }
}
