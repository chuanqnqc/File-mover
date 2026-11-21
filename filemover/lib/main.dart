import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'languages.dart';
import 'l10n/generated/app_localizations.dart';
import 'localized_diagnostics.dart';
import 'migration_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languages = await AppLanguages.load(
    store: WindowsLanguageStore(),
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag(),
  );
  runApp(MyApp(service: WindowsMigrationService(), languages: languages));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.service, this.languages});
  final MigrationService service;
  final AppLanguages? languages;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLanguages languages =
      widget.languages ?? AppLanguages.english();
  @override
  void dispose() {
    if (widget.languages == null) languages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: languages,
    builder: (context, _) => MaterialApp(
      title: 'FileMover',
      locale: languages.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff245b50)),
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: MigrationPage(service: widget.service, languages: languages),
    ),
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
  const MigrationPage({
    super.key,
    required this.service,
    required this.languages,
  });
  final MigrationService service;
  final AppLanguages languages;
  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  bool _languageBusy = false;

  Future<void> _languageAction(String value) async {
    setState(() {
      _languageBusy = true;
    });
    try {
      await widget.languages.select(value);
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
          _error = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _languageBusy = false;
        });
      }
    }
  }

  Widget _diagnostic(String raw) {
    final summary =
        localizedDiagnostic(raw, l10n) ??
        (widget.languages.selected == 'en'
            ? raw
            : l10n.operationFailedReviewTheOriginal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(summary),
        if (summary != raw)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.originalDiagnosticDetails),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SelectableText(raw),
              ),
            ],
          ),
      ],
    );
  }

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
                undo ? l10n.doubleCheckUndo : l10n.doubleCheckMigration,
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
                            ? l10n.moveTheCurrentDataBackTo
                            : l10n.moveThisFolderToTheDestination,
                      ),
                      const SizedBox(height: 20),
                      _detail(l10n.from, review['source'].toString()),
                      _detail(
                        l10n.to,
                        original ?? review['destination'].toString(),
                      ),
                      _detail(
                        l10n.dataSpaceRequired,
                        '${bytes(review['bytes'] as num)} / ${bytes(review['required'] as num)}',
                      ),
                      Text(l10n.everyFileIsCheckedWithSha),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: acknowledged,
                        onChanged: (value) =>
                            update(() => acknowledged = value ?? false),
                        title: Text(l10n.iCheckedBothPathsAndClosed),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: acknowledged
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(undo ? l10n.confirmAndUndo : l10n.confirmAndMove),
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
  String _date(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
  }

  Widget _folder(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !_busy && !_languageBusy && !_pending,
            onChanged: (_) => setState(() {
              _review = null;
            }),
            decoration: InputDecoration(labelText: label),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: l10n.browseFolder(label),
          onPressed: _busy || _languageBusy || _pending
              ? null
              : () => _pick(controller),
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
        PopupMenuButton<String>(
          key: const ValueKey('language-menu'),
          tooltip:
              '${l10n.language} · ${AppLanguages.names[widget.languages.selected]}',
          enabled: !_busy && !_languageBusy,
          icon: const Icon(Icons.language),
          onSelected: _languageAction,
          itemBuilder: (context) => [
            for (final entry in AppLanguages.names.entries)
              CheckedPopupMenuItem(
                value: entry.key,
                checked: widget.languages.selected == entry.key,
                child: Text(entry.value),
              ),
          ],
        ),
        TextButton.icon(
          onPressed: _busy || _languageBusy ? null : _refresh,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.refreshHistory),
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
            if (widget.languages.loadWarning)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(l10n.languageSettingsWarning),
              ),
            Text(
              l10n.heading,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.intro),
            const SizedBox(height: 24),
            if (_pending)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.anOperationNeedsRecoveryOrCleanup),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _folder(l10n.sourceFolder, _source),
                    _folder(l10n.destinationParentFolder, _parent),
                    Text(l10n.theDestinationWillContainAFolder),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _busy ||
                                  _languageBusy ||
                                  _pending ||
                                  _source.text.trim().isEmpty ||
                                  _parent.text.trim().isEmpty
                              ? null
                              : _check,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(l10n.checkFolders),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _busy ||
                                  _languageBusy ||
                                  _pending ||
                                  _review == null
                              ? null
                              : _move,
                          icon: const Icon(Icons.drive_file_move_outline),
                          label: Text(l10n.applyMove),
                        ),
                      ],
                    ),
                    if (_review != null) ...[
                      const Divider(height: 32),
                      _detail(
                        l10n.verifiedDestinationPath,
                        _review!['destination'] as String,
                      ),
                      Text(
                        l10n.fileSummary(
                          _review!['files'] as int,
                          bytes(_review!['bytes'] as num),
                        ),
                      ),
                      Text(
                        l10n.spaceSummary(
                          bytes(_review!['required'] as num),
                          bytes(_review!['free'] as num),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.checksPassedApplyMoveOpensA),
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
                      Text(switch (_progress?['phase']) {
                        'Copying' => l10n.copying,
                        'Verifying' => l10n.verifying,
                        'Recovering' => l10n.recovering,
                        'Switching locations' => l10n.switchingLocations,
                        'Cleaning up' => l10n.cleaningUp,
                        _ => l10n.checkingOperation,
                      }),
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
                                ? l10n.cancellationRequested
                                : l10n.cancelSafely,
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
                  child: _error
                      ? _diagnostic(_message!)
                      : SelectableText(switch (_message) {
                          'Migration verified. The original path now points to the destination.' =>
                            l10n.migrationVerifiedTheOriginalPathNow,
                          'Undo verified. Your current data is back at the original location.' =>
                            l10n.undoVerifiedYourCurrentDataIs,
                          'Recovery completed. Review the operation details below.' =>
                            l10n.recoveryCompletedReviewTheOperationDetails,
                          _ => _message!,
                        }),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              l10n.historyRecovery,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              Text(l10n.migrationsAppearHereInterruptedOperationsCan),
            for (final record in _history) _historyCard(record),
            const SizedBox(height: 24),
            Text(l10n.closeApplicationsUsingTheFolderLive),
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
      'complete': l10n.completed,
      'undone': l10n.undone,
      'rolledBack': l10n.originalLocationRestored,
      'committed': l10n.verifiedCleanupPending,
      'cleanupPending': l10n.verifiedCleanupPending,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.operationStatus(
                r['direction'] == 'undo' ? l10n.undo : l10n.migration,
                labels[state] ?? l10n.recoveryRequired,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _detail(l10n.originalPath, r['source'] as String),
            _detail(l10n.destination, r['destination'] as String),
            Text(_date(r['started'] as String? ?? '')),
            if ((r['message'] as String? ?? '').isNotEmpty)
              _diagnostic(r['message'] as String),
            if (pending || state == 'rolledBack') ...[
              if (r['backup'] != null)
                _detail(l10n.backupPath, r['backup'] as String),
              if (r['stage'] != null)
                _detail(l10n.stagingPath, r['stage'] as String),
            ],
            if (pending)
              FilledButton.tonal(
                onPressed: _busy ? null : () => _recover(r),
                child: Text(
                  cleanup ? l10n.retryCleanup : l10n.recoverOriginalLocation,
                ),
              ),
            if (r['direction'] == 'move' && state == 'complete')
              OutlinedButton(
                onPressed: _busy || _languageBusy || _pending
                    ? null
                    : () => _undo(r),
                child: Text(l10n.undoMigration),
              ),
          ],
        ),
      ),
    );
  }
}
