import 'package:umvvm/umvvm.dart';
import 'package:sample_basic/domain/apis/base/request.dart';
import 'package:sample_basic/domain/apis/posts_api.dart';
import 'package:sample_basic/domain/data/post.dart';
import 'package:sample_basic/domain/global/global_store.dart';
import 'package:sample_basic/domain/interactors/post/post_interactor.dart';
import 'package:test/test.dart';

class MockPostsApi extends PostsApi {
  @override
  HttpRequest<Post?> getPost(int id) => super.getPost(id)
    ..simulateResult = Response(
        code: 200,
        result: Post(
          title: '',
          body: '',
          id: 1,
        ));
}

void main() {
  test('PostsInteractorTest', () async {
    await initApp(testMode: true);

    app.apis.posts = MockPostsApi();

    final postInteractor = PostInteractor();
    app.instances.addTest<PostInteractor>(BaseScopes.global, postInteractor);

    await postInteractor.loadPost(1);

    expect((postInteractor.state.post! as ResultData).result.id, 1);
  });
}
