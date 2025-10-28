import 'package:flutter/material.dart';

class PaintResultsPage extends StatefulWidget {
  final List<Wall> initialWalls;
  final double initialCoveragePerLitre;
  final int initialCoats;
  final double initialBufferPct;

  const PaintResultsPage({
    super.key,
    this.initialWalls = const [],
    this.initialCoveragePerLitre = 10.0,
    this.initialCoats = 2,
    this.initialBufferPct = 10.0,
  });

  @override
  State<PaintResultsPage> createState() => _PaintResultsPageState();
}

class _PaintResultsPageState extends State<PaintResultsPage> {
  late List<Wall> _walls;
  late double _coveragePerLitre; // m2 per litre
  late int _coats;
  late double _bufferPct; // percent

  @override
  void initState() {
    super.initState();
    _walls = [...widget.initialWalls];
    _coveragePerLitre = widget.initialCoveragePerLitre;
    _coats = widget.initialCoats;
    _bufferPct = widget.initialBufferPct;
  }

  double _wallLitres(Wall w) {
    final area = (w.widthM * w.heightM).clamp(0.0, double.infinity);
    final factor = 1.0 + (_bufferPct.clamp(0.0, 100.0) / 100.0);
    return (area * _coats) / (_coveragePerLitre <= 0 ? 1 : _coveragePerLitre) * factor;
  }

  double get _totalLitres => _walls.fold(0.0, (sum, w) => sum + _wallLitres(w));

  String _recommend(double litres) {
    if (!litres.isFinite || litres <= 0) return '--';
    final sizes = [20, 10, 4, 1];
    var remaining = litres;
    final picks = <int, int>{};
    for (final s in sizes) {
      final c = remaining ~/ s;
      if (c > 0) { picks[s] = c; remaining -= c * s; }
    }
    if (remaining > 0) { picks[1] = (picks[1] ?? 0) + 1; }
    return picks.entries.map((e) => '${e.value}x${e.key}L').join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paint Results')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _coveragePerLitre.toStringAsFixed(1),
                    decoration: const InputDecoration(
                      labelText: 'Coverage (m²/L)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d > 0) setState(() => _coveragePerLitre = d);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _coats,
                  items: const [1, 2, 3].map((e) => DropdownMenuItem(value: e, child: Text('$e coats'))).toList(),
                  onChanged: (v) => setState(() => _coats = v ?? 2),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buffer: ${_bufferPct.toStringAsFixed(0)}%'),
                    SizedBox(
                      width: 160,
                      child: Slider(
                        min: 0,
                        max: 20,
                        value: _bufferPct.clamp(0.0, 20.0),
                        onChanged: (v) => setState(() => _bufferPct = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _walls.isEmpty
                ? const Center(child: Text('No walls yet. Use + to add one.'))
                : ListView.separated(
                    itemCount: _walls.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final w = _walls[i];
                      final litres = _wallLitres(w);
                      return ListTile(
                        title: Text(w.name?.isNotEmpty == true ? w.name! : 'Wall ${i + 1}'),
                        subtitle: Text('Width: ${w.widthM.toStringAsFixed(2)} m  •  Height: ${w.heightM.toStringAsFixed(2)} m  •  Area: ${(w.widthM * w.heightM).toStringAsFixed(2)} m²'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${litres.toStringAsFixed(2)} L'),
                            Text(_recommend(litres), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        onTap: () async {
                          final edited = await _showWallDialog(context, initial: w);
                          if (edited != null) setState(() => _walls[i] = edited);
                        },
                        onLongPress: () => setState(() => _walls.removeAt(i)),
                      );
                    },
                  ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${_totalLitres.toStringAsFixed(2)} L'),
                      Text(_recommend(_totalLitres), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _walls.isEmpty ? null : () => _shareOrCopySummary(context),
                  child: const Text('Share'),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final w = await _showWallDialog(context);
          if (w != null) setState(() => _walls.add(w));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Wall?> _showWallDialog(BuildContext context, {Wall? initial}) async {
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final wCtrl = TextEditingController(text: initial?.widthM.toStringAsFixed(2) ?? '');
    final hCtrl = TextEditingController(text: initial?.heightM.toStringAsFixed(2) ?? '');

    return showDialog<Wall>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? 'Add wall' : 'Edit wall'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (optional)')),
            const SizedBox(height: 8),
            TextField(
              controller: wCtrl,
              decoration: const InputDecoration(labelText: 'Width (m)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hCtrl,
              decoration: const InputDecoration(labelText: 'Height (m)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(wCtrl.text.trim());
              final h = double.tryParse(hCtrl.text.trim());
              if (w != null && h != null && w > 0 && h > 0) {
                Navigator.pop(ctx, Wall(widthM: w, heightM: h, name: nameCtrl.text.trim()));
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareOrCopySummary(BuildContext context) {
    final lines = <String>[];
    for (var i = 0; i < _walls.length; i++) {
      final w = _walls[i];
      final litres = _wallLitres(w);
      lines.add('${w.name?.isNotEmpty == true ? w.name : 'Wall ${i + 1}'}: ${(w.widthM * w.heightM).toStringAsFixed(2)} m² → ${litres.toStringAsFixed(2)} L (${_recommend(litres)})');
    }
    lines.add('Total: ${_totalLitres.toStringAsFixed(2)} L (${_recommend(_totalLitres)})');

    final text = lines.join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Summary'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class Wall {
  final double widthM;
  final double heightM;
  final String? name;

  const Wall({required this.widthM, required this.heightM, this.name});
}
