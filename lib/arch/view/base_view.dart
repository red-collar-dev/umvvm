import 'package:flutter/material.dart';
import 'base_view_model.dart';

/// Main class for mvvm redux view
/// It holds reference to view model, receives [WidgetsBinding]
/// post frame callback and manages [AutomaticKeepAliveClientMixin] for this view
///
/// ```dart
/// class PostView extends StatefulWidget {
///
///   @override
///   State<StatefulWidget> createState() {
///     return _PostViewWidgetState();
///   }
/// }
///
/// class _PostViewWidgetState extends BaseView<PostView, PostViewState, PostViewModel> {
///   @override
///   Widget buildView(BuildContext context) {
///     return Container();
///   }
///
///   @override
///   PostViewModel createViewModel() {
///     return PostViewModel();
///   }
/// }
/// ```
abstract class BaseView<View extends StatefulWidget, ScreenState,
        ViewModel extends BaseViewModel<View, ScreenState>> extends State<View>
    with AutomaticKeepAliveClientMixin<View> {
  /// View model for this view
  late ViewModel _viewModel;

  /// View model for this view
  ViewModel get viewModel => _viewModel;

  @override
  void initState() {
    super.initState();

    initializeViewModel();

    viewModel.onLaunch(widget);
  }

  @override
  bool get wantKeepAlive => isInnerView;

  /// Initializes view model
  void initializeViewModel() {
    _viewModel = createViewModel();
    _viewModel.inititialze(widget);
  }

  @override
  void dispose() {
    super.dispose();
    _viewModel.dispose();
  }

  /// Factory method for view model for this view
  ViewModel createViewModel();

  Widget buildView(BuildContext context);

  bool get isInnerView => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return buildView(context);
  }
}
