import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Simple client for the Visualizer backend.
/// Backend is expected to expose POST /visualize that returns { image_url: string }
class VisualizerService {
  VisualizerService._();
  static final VisualizerService instance = VisualizerService._();

  // Read endpoint from --dart-define, fallback to localhost for dev.
  static String get _baseUrl => const String.fromEnvironment(
        'VIZ_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      );

  void _validateBaseUrl() {
    final raw = _baseUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        (uri.host.isEmpty && uri.authority.isEmpty)) {
      throw Exception(
          'Visualizer backend URL is not configured. Set VIZ_BASE_URL to http(s)://host:port');
    }
  }

  Future<String> visualize(File image, String colorHex,
      {String scene = 'auto'}) async {
    _validateBaseUrl();
    final uri = Uri.parse('$_baseUrl/visualize');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['color_hex'] = colorHex
        ..fields['scene'] = scene
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      final resp = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final contentType = resp.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          throw Exception('Unexpected server response');
        }
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = data['image_url'] as String?;
        if (url == null || url.isEmpty) {
          throw Exception('Visualization failed: empty result');
        }
        return url;
      } else if (resp.statusCode == 413) {
        throw Exception('Image is too large. Try a smaller photo.');
      } else if (resp.statusCode == 400) {
        throw Exception(
            'This photo could not be processed. Try a clearer wall/house view.');
      } else {
        throw Exception('Visualization failed (${resp.statusCode}).');
      }
    } on TimeoutException {
      throw Exception('The server took too long. Please try again later.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FileSystemException {
      throw Exception('Could not read the selected image.');
    }
  }
}
