import 'package:flutter_riverpod/flutter_riverpod.dart';

final app_stateProvider = NotifierProvider<app_state, int>(app_state.new);

class app_state extends Notifier<int> {
  @override
  int build() => 0; // 初始 pageIndex

  int get pageIndex => state;

  set setPageIndex(int index) {
    state = index;
  }
}
