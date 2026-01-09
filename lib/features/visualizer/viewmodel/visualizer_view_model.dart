import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/services/visualizer_service.dart';
import 'package:flutter/material.dart';

class VisualizerState {
  final bool processing;
  final String? resultUrl;
  final String? error;
  final Color color;

  const VisualizerState({
    required this.processing,
    required this.color,
    this.resultUrl,
    this.error,
  });

  VisualizerState copyWith({
    bool? processing,
    String? resultUrl,
    String? error,
    Color? color,
  }) {
    return VisualizerState(
      processing: processing ?? this.processing,
      resultUrl: resultUrl,
      error: error,
      color: color ?? this.color,
    );
  }

  static VisualizerState initial() => const VisualizerState(
        processing: false,
        resultUrl: null,
        error: null,
        color: Color(0xFFEF5350),
      );
}

class VisualizerViewModel extends StateNotifier<VisualizerState> {
  VisualizerViewModel() : super(VisualizerState.initial());

  void setColor(Color c) =>
      state = state.copyWith(color: c, resultUrl: null, error: null);

  Future<void> visualize(File image, {String scene = 'auto'}) async {
    if (state.processing) return;
    state = state.copyWith(processing: true, resultUrl: null, error: null);
    try {
      final c = state.color;
      final hex = '#'
              '${c.red.toRadixString(16).padLeft(2, '0')}'
              '${c.green.toRadixString(16).padLeft(2, '0')}'
              '${c.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
      final url =
          await VisualizerService.instance.visualize(image, hex, scene: scene);
      state = state.copyWith(processing: false, resultUrl: url, error: null);
    } catch (e) {
      state = state.copyWith(
          processing: false, error: e.toString(), resultUrl: null);
    }
  }

  void clearResult() => state = state.copyWith(resultUrl: null, error: null);
}
