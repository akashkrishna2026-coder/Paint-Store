import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/notifications_repository.dart';
import 'package:c_h_p/data/repositories/user_repository.dart';

class NotifEntry {
  final String key; // For global, a synthetic key based on signature
  final Map<String, dynamic> data;
  final String src; // 'p' personal, 'g' global
  NotifEntry({required this.key, required this.data, required this.src});
}

class NotificationsState {
  final bool loading;
  final List<NotifEntry> entries;
  final Object? error;
  const NotificationsState({
    this.loading = false,
    this.entries = const [],
    this.error,
  });

  NotificationsState copyWith({
    bool? loading,
    List<NotifEntry>? entries,
    Object? error,
  }) =>
      NotificationsState(
        loading: loading ?? this.loading,
        entries: entries ?? this.entries,
        error: error,
      );
}

class NotificationsViewModel extends StateNotifier<NotificationsState> {
  NotificationsViewModel(this._repo, this._userRepo)
      : super(const NotificationsState());
  final NotificationsRepository _repo;
  final UserRepository _userRepo;

  StreamSubscription<Map<String, Map<String, dynamic>>>? _personalSub;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _globalSub;
  StreamSubscription<Map<String, dynamic>>? _dismissedSub;
  String? _role;

  Map<String, Map<String, dynamic>> _personal = {};
  Map<String, Map<String, dynamic>> _global = {};
  Set<String> _dismissed = {};

  Future<void> start(String uid) async {
    state = state.copyWith(loading: true, error: null);
    try {
      _role = await _userRepo.fetchUserRole(uid);
      _listen(uid);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void _listen(String uid) {
    _personalSub?.cancel();
    _globalSub?.cancel();
    _dismissedSub?.cancel();

    _dismissedSub = _repo.dismissedMapStream(uid).listen((map) {
      _dismissed = map.keys.map((k) => k.toString()).toSet();
      _recompute();
    });

    _personalSub = _repo.personalStream(uid).listen((map) {
      _personal = map;
      _recompute();
    });

    final isAdmin = _role == 'Admin';
    final isManager = _role == 'Manager';
    if (isAdmin || isManager) {
      final stream =
          isAdmin ? _repo.globalAdminsStream() : _repo.globalManagersStream();
      _globalSub = stream.listen((map) {
        _global = map;
        _recompute();
      });
    } else {
      _global = {};
    }
  }

  void _recompute() {
    final List<NotifEntry> out = [];
    final Set<String> seen = {};

    void addAll(String src, Map<String, Map<String, dynamic>> map) {
      map.forEach((k, v) {
        final ts = (v['timestamp'] ?? 0).toString();
        final msg = (v['message'] ?? '').toString();
        final type = (v['type'] ?? '').toString();
        final sig = '$type|$ts|$msg';
        if (src == 'g') {
          if (_dismissed.contains(sig)) return;
          if (seen.add(sig)) out.add(NotifEntry(key: sig, data: v, src: src));
        } else {
          // personal
          if (seen.add('p|$k')) out.add(NotifEntry(key: k, data: v, src: src));
        }
      });
    }

    addAll('p', _personal);
    addAll('g', _global);

    out.sort((a, b) {
      final at = (a.data['timestamp'] ?? 0) as int;
      final bt = (b.data['timestamp'] ?? 0) as int;
      return bt.compareTo(at);
    });

    state = state.copyWith(entries: out);
  }

  Future<void> markAllRead(String uid) => _repo.markAllRead(uid);
  Future<void> clearAll(String uid) => _repo.clearAll(uid);
  Future<void> dismissGlobal(String uid, String signature) =>
      _repo.dismissGlobal(uid, signature);
  Future<void> deletePersonal(String uid, String key) =>
      _repo.deletePersonal(uid, key);

  @override
  void dispose() {
    _personalSub?.cancel();
    _globalSub?.cancel();
    _dismissedSub?.cancel();
    super.dispose();
  }
}
