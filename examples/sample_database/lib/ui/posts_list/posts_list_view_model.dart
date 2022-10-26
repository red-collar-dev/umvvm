import 'package:mvvm_redux/mvvm_redux.dart';
import 'package:sample_database/domain/data/post.dart';
import 'package:sample_database/domain/data/stateful_data.dart';
import 'package:sample_database/domain/global/global_store.dart';
import 'package:sample_database/domain/interactors/navigation/components/routes.dart';
import 'package:sample_database/domain/interactors/navigation/navigation_interactor.dart';
import 'package:sample_database/domain/interactors/posts/posts_interactor.dart';
import 'package:sample_database/domain/interactors/posts/posts_state.dart';

import 'posts_list_view.dart';
import 'posts_list_view_state.dart';

class PostsListViewModel extends BaseViewModel<PostsListView, PostsListViewState> {
  @override
  List<Connector> get dependsOn => [
        Connector(interactor: PostsInteractor),
      ];

  @override
  void onLaunch(PostsListView widget) {
    interactors.get<PostsInteractor>().loadPosts(0, 30);
  }

  void like(int id) {
    interactors.get<PostsInteractor>().likePost(id);
  }

  void openPost(Post post) {
    app.interactors.get<NavigationInteractor>().routeTo(Routes.post, payload: {
      'post': post,
    });
  }

  Stream<StatefulData<List<Post>>?> get postsStream => interactors.get<PostsInteractor>().updates((state) => state.posts);
  // Stream<StoreChange<StatefulData<List<Post>>?>> get postsChangesStream => interactors.get<PostsInteractor>().changes((state) => state.posts);
}
