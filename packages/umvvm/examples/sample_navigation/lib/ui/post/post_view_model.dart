import 'package:umvvm/umvvm.dart';
import 'package:sample_navigation/domain/data/post.dart';
import 'package:sample_navigation/domain/global/global_store.dart';
import 'package:sample_navigation/domain/interactors/navigation/navigation_interactor.dart';
import 'package:sample_navigation/domain/interactors/post/post_interactor.dart';

import 'post_view.dart';
import 'post_view_state.dart';

class PostViewModel extends NavigationViewModel<PostView, PostViewState> {
  @override
  List<Connector> dependsOn(PostView input) => [
        app.connectors.postInteractorConnector(scope: BaseScopes.unique),
      ];

  @override
  void onLaunch(PostView widget) {
    final postInteractor = getLocalInstance<PostInteractor>();

    if (widget.post == null) {
      postInteractor.loadPost(widget.id!);
    } else {
      postInteractor.useExistingPost(widget.post!);
    }
  }

  void like(int id) {
    getLocalInstance<PostInteractor>().likePost(id);
  }

  void openTestDialog() {
    app.instances
        .get<NavigationInteractor>()
        .showDialog(app.navigation.dialogs.error(), dismissable: false);
  }

  void openTestBottomSheet() {
    app.instances.get<NavigationInteractor>().showBottomSheet(
          app.navigation.bottomSheets.authorization(),
          dismissable: false,
        );
  }

  Stream<StatefulData<Post>?> get postStream =>
      getLocalInstance<PostInteractor>().updates((state) => state.post);

  StatefulData<Post>? get initialPost =>
      getLocalInstance<PostInteractor>().state.post;

  @override
  PostViewState initialState(PostView input) => PostViewState();
}
