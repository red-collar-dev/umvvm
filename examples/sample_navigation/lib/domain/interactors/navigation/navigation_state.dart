import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample_navigation/domain/data/app_tab.dart';

part 'navigation_state.freezed.dart';

@freezed
class NavigationState with _$NavigationState {
  factory NavigationState({
    AppTab? currentTab,
  }) = _NavigationState;
}
