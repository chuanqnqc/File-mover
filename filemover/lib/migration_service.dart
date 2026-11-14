import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

typedef JsonMap = Map<String, dynamic>;

abstract class MigrationService {
  Future<String?> pickFolder();
  Future<dynamic> run(
    String action, {
    String? source,
    String? parent,
    String? id,
    void Function(JsonMap)? onProgress,
  });
  Future<void> cancel();
}

class WindowsMigrationService implements MigrationService {
  static const _channel = MethodChannel('filemover/folders');
  late final Directory _root = Directory(
    '${Platform.environment['LOCALAPPDATA']}\\FileMover',
  );
  Future<void>? _ready;
  bool _running = false;

  Future<void> _prepare() async {
    if (!Platform.isWindows) {
      throw UnsupportedError('FileMover requires Windows.');
    }
    final worker = Directory('${_root.path}\\worker-v1');
    await worker.create(recursive: true);
    for (final name in ['worker.ps1', 'engine.cs']) {
      final content = await rootBundle.loadString('assets/$name');
      final file = File('${worker.path}\\$name');
      if (!await file.exists() || await file.readAsString() != content) {
        await file.writeAsString(content, flush: true);
      }
    }
  }

  @override
  Future<String?> pickFolder() => _channel.invokeMethod<String>('pickFolder');

  @override
  Future<dynamic> run(
    String action, {
    String? source,
    String? parent,
    String? id,
    void Function(JsonMap)? onProgress,
  }) async {
    if (_running) throw StateError('An operation is already running.');
    _running = true;
    try {
      await (_ready ??= _prepare());
      final request = base64Encode(
        utf8.encode(
          jsonEncode({
            'action': action,
            'source': source,
            'parent': parent,
            'id': id,
            'dataRoot': '${_root.path}\\operations',
          }),
        ),
      );
      final systemRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
      // Only data is passed as arguments; no paths are evaluated as shell code.
      final process = await Process.start(
        '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
        [
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          '${_root.path}\\worker-v1\\worker.ps1',
          '-EnginePath',
          '${_root.path}\\worker-v1\\engine.cs',
          '-RequestBase64',
          request,
        ],
      );
      final errors = process.stderr.transform(utf8.decoder).join();
      dynamic result;
      String? failure;
      bool received = false;
      await for (final line
          in process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final event = jsonDecode(line) as JsonMap;
          switch (event['type']) {
            case 'progress':
              onProgress?.call(event['data'] as JsonMap);
            case 'result':
              result = event['data'];
              received = true;
            case 'error':
              failure =
                  (event['data'] as JsonMap?)?['message'] as String? ??
                  event['message'] as String? ??
                  'Windows worker failed.';
          }
        } on FormatException {
          failure = 'Unexpected worker response: $line';
        }
      }
      final code = await process.exitCode;
      final stderr = await errors;
      if (failure != null) throw MigrationException(failure);
      if (code != 0 || !received) {
        throw MigrationException(
          'Worker stopped. Open History to recover. ${stderr.trim()}',
        );
      }
      return result;
    } finally {
      _running = false;
    }
  }

  @override
  Future<void> cancel() =>
      File('${_root.path}\\operations\\cancel')
          .writeAsString('cancel', flush: true)
          .then((_) {});
}

class MigrationException implements Exception {
  const MigrationException(this.message);
  final String message;
  @override
  String toString() => message;
}
