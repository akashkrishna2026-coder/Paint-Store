import 'dart:convert';
import 'dart:io';

// Usage: dart json_to_markdown.dart <input_json> <output_md>
// Converts Flutter test JSON (-r json) into a compact Markdown summary.

void main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart json_to_markdown.dart <input_json> <output_md>');
    exit(64);
  }

  final input = File(args[0]);
  final output = File(args[1]);

  if (!await input.exists()) {
    stderr.writeln('Input not found: ${input.path}');
    exit(66);
  }

  final lines = await input.readAsLines();
  // The JSON reporter emits a JSON object per line.
  final events = lines.map((l) {
    try {
      return json.decode(l);
    } catch (_) {
      return null;
    }
  }).where((e) => e != null).cast<Map<String, dynamic>>().toList();

  int passed = 0, failed = 0, skipped = 0, total = 0;
  final List<Map<String, dynamic>> failures = [];

  for (final e in events) {
    if (e['type'] == 'testStart') {
      total++;
    }
    if (e['type'] == 'testDone') {
      final ok = e['result'] == 'success';
      final skip = e['skipped'] == true;
      if (ok) passed++;
      if (skip) skipped++;
      if (!ok && !skip) failed++;
    }
    if (e['type'] == 'error' || e['type'] == 'print' || e['type'] == 'testDone') {
      // Collect failure info at end if failed
    }
  }

  // Collect names for failed tests
  final Map<int, String> testNames = {};
  for (final e in events) {
    if (e['type'] == 'testStart') {
      final id = e['test']['id'];
      final name = e['test']['name'];
      testNames[id] = name;
    }
  }
  final Set<int> failedIds = {};
  for (final e in events) {
    if (e['type'] == 'testDone') {
      final id = e['testID'];
      final ok = e['result'] == 'success';
      final skip = e['skipped'] == true;
      if (!ok && !skip) failedIds.add(id);
    }
  }
  for (final id in failedIds) {
    final buffer = StringBuffer();
    for (final e in events) {
      if (e['testID'] == id && (e['type'] == 'error' || e['type'] == 'print')) {
        buffer.writeln(e['error'] ?? e['message'] ?? e['text'] ?? '');
      }
    }
    failures.add({
      'id': id,
      'name': testNames[id] ?? 'Test #$id',
      'details': buffer.toString().trim(),
    });
  }

  final md = StringBuffer()
    ..writeln('# Integration Test Report')
    ..writeln()
    ..writeln('- **Total**: $total')
    ..writeln('- **Passed**: $passed')
    ..writeln('- **Failed**: $failed')
    ..writeln('- **Skipped**: $skipped')
    ..writeln()
    ..writeln('## Failures')
    ..writeln(failures.isEmpty ? 'None' : '')
    ..writeln();

  for (final f in failures) {
    md.writeln('- **${f['name']}**');
    if ((f['details'] as String).isNotEmpty) {
      md.writeln('  ```');
      md.writeln(f['details']);
      md.writeln('  ```');
    }
  }

  await output.writeAsString(md.toString());
}
