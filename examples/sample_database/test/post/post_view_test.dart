import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mvvm_redux/arch/http/base_request.dart';
import 'package:sample/domain/apis/base/request.dart';
import 'package:sample/domain/apis/posts_api.dart';
import 'package:sample/domain/data/post.dart';
import 'package:sample/domain/global/global_store.dart';
import 'package:sample/ui/post/post_view.dart';

class MockPostsApi extends PostsApi {
  @override
  HttpRequest<Post?> getPost(int id) => super.getPost(id)
    ..simulateResult = Response(code: 200, result: Post(
      title: 'TestTitle',
      body: 'TestBody',
      id: 1,
    ));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PostViewTest', () {
    testWidgets('PostViewTest InitialLoadTest', (tester) async {
      await initApp(testMode: true);
      
      app
        ..registerBuilders()
        ..registerSingletons();

      app.apis.posts = MockPostsApi();

      await tester.pumpAndSettle();

      await tester.pumpWidget(MaterialApp(
        home: Material(child: PostView(id: 1)),
      ));

      await Future.delayed(const Duration(seconds: 3), () {});

      await tester.pumpAndSettle();

      final titleFinder = find.text('TestTitle');

      expect(titleFinder, findsOneWidget);
    });
  });
}
