import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/painters_repository.dart';
import 'package:c_h_p/model/painter_model.dart';

class PaintersState {
  final bool loading;
  final List<Painter> painters;
  final Object? error;
  const PaintersState({
    this.loading = false,
    this.painters = const [],
    this.error,
  });

  PaintersState copyWith({
    bool? loading,
    List<Painter>? painters,
    Object? error,
  }) =>
      PaintersState(
        loading: loading ?? this.loading,
        painters: painters ?? this.painters,
        error: error,
      );
}

class PaintersViewModel extends StateNotifier<PaintersState> {
  PaintersViewModel(this._repo) : super(const PaintersState()) {
    _subscribe();
  }
  final PaintersRepository _repo;
  StreamSubscription<List<Painter>>? _sub;

  void _subscribe() {
    state = state.copyWith(loading: true, error: null);
    _sub?.cancel();
    _sub = _repo.paintersStream().listen((list) {
      state = state.copyWith(loading: false, painters: list, error: null);
    }, onError: (e) {
      state = state.copyWith(loading: false, error: e);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
