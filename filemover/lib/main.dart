import 'package:material_ui/material_ui.dart';

import 'migration_service.dart';

void main() => runApp(MyApp(service: WindowsMigrationService()));

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.service});
  final MigrationService service;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FileMover',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff245b50)),
      scaffoldBackgroundColor: const Color(0xfff5f7f6),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: MigrationPage(service: service),
  );
}

String bytes(num value) {
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  double n = value.toDouble();
  int unit = 0;
  while (n >= 1024 && unit < units.length - 1) {
    n /= 1024;
    unit++;
  }
  return '${n.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key, required this.service});
  final MigrationService service;
  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  final _source = TextEditingController(), _parent = TextEditingController();
  List<JsonMap> _history = [];
  JsonMap? _review, _progress;
  bool _busy = false, _cancelRequested = false, _error = false;
  String? _message;
  bool get _pending => _history.any(
    (r) => !['complete', 'undone', 'rolledBack'].contains(r['state']),
  );
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _source.dispose();
    _parent.dispose();
    super.dispose();
  }

  List<JsonMap> _records(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<void> _refresh() => _execute(() async {
    _history = _records(await widget.service.run('history'));
  });
  Future<void> _execute(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _cancelRequested = false;
      _message = null;
      _progress = null;
    });
    try {
      await action();
    } catch (e) {
      _message = e.toString();
      _error = true;
      try {
        _history = _records(await widget.service.run('history'));
      } catch (_) {
        /* Preserve the original error. */
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  void _onProgress(JsonMap value) {
    if (mounted) {
      setState(() {
        _progress = value;
      });
    }
  }

  Future<void> _pick(TextEditingController controller) async {
    try {
      final path = await widget.service.pickFolder();
      if (path != null && mounted) {
        setState(() {
          controller.text = path;
          _review = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
          _error = true;
        });
      }
    }
  }

  Future<void> _check() => _execute(() async {
    _review = null;
    _review = Map<String, dynamic>.from(
      await widget.service.run(
        'preflight',
        source: _source.text.trim(),
        parent: _parent.text.trim(),
        onProgress: _onProgress,
      ) as Map,
    );
  });
  Future<bool> _confirm(
    JsonMap review, {
    bool undo = false,
    String? original,
  }) async {
    bool acknowledged = false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
              title: Text(
                undo ? 'Double-check undo' : 'Double-check migration',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        undo
                            ? 'Move the current data back to the original location and remove the junction.'
                            : 'Move this folder to the destination and leave a junction at the original path.',
                      ),
                      const SizedBox(height: 20),
                      _detail('From', review['source'].toString()),
                      _detail(
                        'To',
                        original ?? review['destination'].toString(),
                      ),
                      _detail(
                        'Data / space required',
                        '${bytes(review['bytes'] as num)} / ${bytes(review['required'] as num)}',
                      ),
                      const Text(
                        'Every file is checked with SHA-256 before switching locations. Keep applications closed until this finishes.',
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: acknowledged,
                        onChanged: (value) =>
                            update(() => acknowledged = value ?? false),
                        title: const Text(
                          'I checked both paths and closed applications using this folder.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: acknowledged
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(undo ? 'Confirm and undo' : 'Confirm and move'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _move() async {
    final review = _review;
    if (review == null || !await _confirm(review) || !mounted) return;
    await _execute(() async {
      _history = _records(
        await widget.service.run(
          'move',
          source: review['source'] as String,
          parent: review['parent'] as String,
          onProgress: _onProgress,
        ),
      );
      _review = null;
      _message = 'Migration verified. The original path now points to the destination.';
      _error = false;
    });
  }

  Future<void> _undo(JsonMap record) async {
    JsonMap? review;
    await _execute(() async {
      review = Map<String, dynamic>.from(
        await widget.service.run(
          'undoPreflight',
          id: record['id'] as String,
          onProgress: _onProgress,
        ) as Map,
      );
    });
    if (review == null ||
        !mounted ||
        !await _confirm(
          review!,
          undo: true,
          original: record['source'] as String,
        ) ||
        !mounted) {
      return;
    }
    await _execute(() async {
      _history = _records(
        await widget.service.run(
          'undo',
          id: record['id'] as String,
          onProgress: _onProgress,
        ),
      );
      _message =
          'Undo verified. Your current data is back at the original location.';
      _error = false;
    });
  }

  Future<void> _recover(JsonMap record) => _execute(() async {
    _history = _records(
      await widget.service.run(
        'recover',
        id: record['id'] as String,
        onProgress: _onProgress,
      ),
    );
    _message = 'Recovery completed. Review the operation details below.';
    _error = false;
  });
  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        SelectableText(value),
      ],
    ),
  );
  Widget _folder(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !_busy && !_pending,
            onChanged: (_) => setState(() {
              _review = null;
            }),
            decoration: InputDecoration(labelText: label),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Browse $label',
          onPressed: _busy || _pending ? null : () => _pick(controller),
          icon: const Icon(Icons.folder_open),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FileMover'),
      actions: [
        TextButton.icon(
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh history'),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text(
              'Move the data. Keep the path.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Safely relocate a Windows folder and leave a junction at its original location. Local NTFS drives only.',
            ),
            const SizedBox(height: 24),
            if (_pending)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'An operation needs recovery or cleanup. Resolve it in History before starting another move.',
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _folder('Source folder', _source),
                    _folder('Destination parent folder', _parent),
                    const Text(
                      'The destination will contain a folder with the same name. Existing folders are never overwritten.',
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _busy ||
                                  _pending ||
                                  _source.text.trim().isEmpty ||
                                  _parent.text.trim().isEmpty
                              ? null
                              : _check,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Check folders'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || _pending || _review == null
                              ? null
                              : _move,
                          icon: const Icon(Icons.drive_file_move_outline),
                          label: const Text('Apply move'),
                        ),
                      ],
                    ),
                    if (_review != null) ...[
                      const Divider(height: 32),
                      _detail(
                        'Verified destination path',
                        _review!['destination'] as String,
                      ),
                      Text(
                        '${_review!['files']} files · ${bytes(_review!['bytes'] as num)} of data',
                      ),
                      Text(
                        '${bytes(_review!['required'] as num)} required · ${bytes(_review!['free'] as num)} available',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Checks passed. Apply move opens a final confirmation. Checks run again before moving data.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_busy)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _progress?['phase'] as String? ?? 'Checking operation…',
                      ),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      if (_progress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _progress!['path'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if ([
                        'Copying',
                        'Verifying',
                      ].contains(_progress?['phase']))
                        TextButton(
                          onPressed: _cancelRequested
                              ? null
                              : () async {
                                  setState(() {
                                    _cancelRequested = true;
                                  });
                                  try {
                                    await widget.service.cancel();
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _message = e.toString();
                                        _error = true;
                                      });
                                    }
                                  }
                                },
                          child: Text(
                            _cancelRequested
                                ? 'Cancellation requested…'
                                : 'Cancel safely',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_message != null)
              Card(
                color: _error
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(_message!),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'History & recovery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Text(
                'Migrations appear here. Interrupted operations can be recovered after restarting FileMover.',
              ),
            for (final record in _history) _historyCard(record),
            const SizedBox(height: 24),
            const Text(
              'Close applications using the folder. Live databases, system folders, network locations, encrypted files, and folders containing links are unsupported.',
            ),
          ],
        ),
      ),
    ),
  );

  Widget _historyCard(JsonMap r) {
    final state = r['state'] as String;
    final pending = !['complete', 'undone', 'rolledBack'].contains(state);
    final cleanup = ['committed', 'cleanupPending'].contains(state);
    final labels = {
      'complete': 'Completed',
      'undone': 'Undone',
      'rolledBack': 'Original location restored',
      'committed': 'Verified · cleanup pending',
      'cleanupPending': 'Verified · cleanup pending',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r['direction'] == 'undo' ? 'Undo' : 'Migration'} · ${labels[state] ?? 'Recovery required'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _detail('Original path', r['source'] as String),
            _detail('Destination', r['destination'] as String),
            Text(r['started'] as String? ?? ''),
            if ((r['message'] as String? ?? '').isNotEmpty)
              SelectableText(r['message'] as String),
            if (pending || state == 'rolledBack') ...[
              if (r['backup'] != null)
                _detail('Backup path', r['backup'] as String),
              if (r['stage'] != null)
                _detail('Staging path', r['stage'] as String),
            ],
            if (pending)
              FilledButton.tonal(
                onPressed: _busy ? null : () => _recover(r),
                child: Text(
                  cleanup ? 'Retry cleanup' : 'Recover original location',
                ),
              ),
            if (r['direction'] == 'move' && state == 'complete')
              OutlinedButton(
                onPressed: _busy || _pending ? null : () => _undo(r),
                child: const Text('Undo migration'),
              ),
          ],
        ),
      ),
    );
  }
}
