import 'package:mvvm_redux/mvvm_redux.dart';
import 'package:sample_basic/domain/data/post.dart';
import 'package:sample_basic/domain/data/stateful_data.dart';
import 'package:sample_basic/domain/interactors/post/post_interactor.dart';

import 'post_view.dart';
import 'post_view_state.dart';

class PostViewModel extends BaseViewModel<PostView, PostViewState> {
  @override
  List<Connector> get dependsOn => [
        Connector(interactor: PostInteractor, unique: true),
      ];

  @override
  void onLaunch(PostView widget) {
    final postInteractor = interactors.get<PostInteractor>();

    if (widget.post == null) {
      postInteractor.loadPost(widget.id!);
    } else {
      postInteractor.useExistingPost(widget.post!);
    }
  }

  void like(int id) {
    interactors.get<PostInteractor>().likePost(id);
  }

  Stream<StatefulData<Post>?> get postStream => interactors.get<PostInteractor>().updates((state) => state.post);
}
