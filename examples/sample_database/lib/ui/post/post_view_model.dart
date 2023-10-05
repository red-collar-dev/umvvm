import 'package:umvvm/umvvm.dart';
import 'package:sample_database/domain/data/post.dart';
import 'package:sample_database/domain/global/global_store.dart';
import 'package:sample_database/domain/interactors/navigation/components/bottom_sheets/bottom_sheets.dart';
import 'package:sample_database/domain/interactors/navigation/components/dialogs/dialogs.dart';
import 'package:sample_database/domain/interactors/navigation/navigation_interactor.dart';
import 'package:sample_database/domain/interactors/post/post_interactor.dart';

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
        .showDialog(Dialogs.error(), dismissable: false);
  }

  void openTestBottomSheet() {
    app.navigation
        .showBottomSheet(BottomSheets.autharization(), dismissable: false);
  }

  Stream<StatefulData<Post>?> get postStream =>
      getLocalInstance<PostInteractor>().updates((state) => state.post);

  @override
  PostViewState initialState(PostView input) => PostViewState();

  StatefulData<Post>? get initialPost =>
      getLocalInstance<PostInteractor>().state.post;
}
