import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/report_repository.dart';

class ReportState {
  final bool submitting;
  final Object? error;
  const ReportState({this.submitting = false, this.error});

  ReportState copyWith({bool? submitting, Object? error}) => ReportState(
        submitting: submitting ?? this.submitting,
        error: error,
      );
}

class ReportViewModel extends StateNotifier<ReportState> {
  ReportViewModel(this._repo) : super(const ReportState());
  final ReportRepository _repo;

  Future<void> submitIssue(String issueText) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await _repo.submitIssue(issueText);
      state = state.copyWith(submitting: false);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
      rethrow;
    }
  }

  Stream<List<MapEntry<String, Map<String, dynamic>>>> reportsStream() =>
      _repo.reportsStream();

  Future<void> resolve({
    required String reportKey,
    required String userId,
    required String issueText,
  }) =>
      _repo.resolveReport(
          reportKey: reportKey, userId: userId, issueText: issueText);
}
