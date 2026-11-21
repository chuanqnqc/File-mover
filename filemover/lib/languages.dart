import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const maxLanguageBytes = 1024 * 1024;

class LanguagePack {
  const LanguagePack({
    required this.locale,
    required this.name,
    required this.messages,
    this.direction = 'ltr',
  });
  final String locale, name, direction;
  final Map<String, String> messages;

  static Set<String> placeholders(String text) =>
      RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}')
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toSet();

  factory LanguagePack.parse(String source, {Set<String>? knownKeys}) {
    if (utf8.encode(source).length > maxLanguageBytes) {
      throw const FormatException('Language files must be smaller than 1 MiB.');
    }
    final value = jsonDecode(source.replaceFirst(RegExp('^\uFEFF'), ''));
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['locale'] is! String ||
        value['name'] is! String ||
        value['messages'] is! Map) {
      throw const FormatException(
        'Expected schemaVersion, locale, name, and messages.',
      );
    }
    final locale = value['locale'] as String;
    final name = (value['name'] as String).trim();
    final direction = value['direction'] ?? 'ltr';
    if (locale.length > 64 ||
        !RegExp(r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$').hasMatch(locale) ||
        name.isEmpty ||
        name.length > 80 ||
        !['ltr', 'rtl'].contains(direction)) {
      throw const FormatException(
        'Invalid locale, language name, or text direction.',
      );
    }
    final messages = <String, String>{};
    for (final entry in (value['messages'] as Map).entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          (entry.value as String).trim().isEmpty ||
          (entry.value as String).length > 4000 ||
          (knownKeys != null && !knownKeys.contains(entry.key))) {
        throw const FormatException(
          'Unknown message key or invalid translation.',
        );
      }
      final original = placeholders(entry.key as String);
      final translated = placeholders(entry.value as String);
      if (original.length != translated.length ||
          !original.containsAll(translated)) {
        throw const FormatException(
          'Translation placeholders must match the original message.',
        );
      }
      messages[entry.key as String] = entry.value as String;
    }
    if (messages.isEmpty) {
      throw const FormatException('Include at least one translated message.');
    }
    return LanguagePack(
      locale: locale,
      name: name,
      direction: direction as String,
      messages: Map.unmodifiable(messages),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'locale': locale,
    'name': name,
    'direction': direction,
    'messages': messages,
  };
}

abstract class LanguageStore {
  Future<String?> read();
  Future<void> write(String contents);
  Future<String?> pickJson();
}

class WindowsLanguageStore implements LanguageStore {
  static const _channel = MethodChannel('filemover/folders');
  WindowsLanguageStore({File? settings})
    : _settings =
          settings ??
          File(
            '${Platform.environment['LOCALAPPDATA']}\\FileMover\\languages.json',
          );
  final File _settings;
  @override
  Future<String?> read() async {
    if (!await _settings.exists()) return null;
    if (await _settings.length() > maxLanguageBytes * 21) {
      throw const FormatException('Saved language settings are too large.');
    }
    return _settings.readAsString();
  }

  @override
  Future<void> write(String contents) async {
    await _settings.parent.create(recursive: true);
    final temporary = File(
      '${_settings.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(_settings.path);
  }

  @override
  Future<String?> pickJson() async {
    final path = await _channel.invokeMethod<String>('pickLanguageFile');
    if (path == null) return null;
    final file = File(path);
    if (await file.length() > maxLanguageBytes) {
      throw const FormatException('Language files must be smaller than 1 MiB.');
    }
    // Bound the actual read too, in case the file grows after the length check.
    final data = await file
        .openRead(0, maxLanguageBytes + 1)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (data.length > maxLanguageBytes) {
      throw const FormatException('Language files must be smaller than 1 MiB.');
    }
    return utf8.decode(data);
  }
}

class MemoryLanguageStore implements LanguageStore {
  String? contents;
  String? importContents;
  @override
  Future<String?> read() async => contents;
  @override
  Future<void> write(String value) async {
    contents = value;
  }

  @override
  Future<String?> pickJson() async => importContents;
}

class AppLanguages extends ChangeNotifier {
  AppLanguages._(this._builtins, this.store, this._selected);
  factory AppLanguages.english() => AppLanguages._(
    {'en': const LanguagePack(locale: 'en', name: 'English', messages: {})},
    MemoryLanguageStore(),
    'en',
  );

  final Map<String, LanguagePack> _builtins;
  final LanguageStore store;
  Map<String, LanguagePack> _imported = {};
  String _selected;
  String? loadWarning;
  String get selected => _selected;
  Map<String, LanguagePack> get packs =>
      Map.unmodifiable({..._builtins, ..._imported});
  LanguagePack get current => packs[_selected]!;
  Set<String> get messageKeys => _builtins['en']!.messages.keys.toSet();

  static Future<AppLanguages> load({
    required LanguageStore store,
    String systemLocale = 'en',
  }) async {
    final builtins = <String, LanguagePack>{};
    for (final code in ['en', 'zh-Hans']) {
      final pack = LanguagePack.parse(
        await rootBundle.loadString('assets/languages/$code.json'),
      );
      builtins[pack.locale] = pack;
    }
    final result = AppLanguages._(
      builtins,
      store,
      systemLocale.toLowerCase().startsWith('zh') ? 'zh-Hans' : 'en',
    );
    try {
      final saved = await store.read();
      if (saved != null) {
        final value = jsonDecode(saved);
        if (value is! Map ||
            value['schemaVersion'] != 1 ||
            value['packs'] is! List ||
            value['selected'] is! String) {
          throw const FormatException('Invalid saved language settings.');
        }
        final imports = <String, LanguagePack>{};
        for (final raw in value['packs'] as List) {
          final pack = LanguagePack.parse(
            jsonEncode(raw),
            knownKeys: builtins['en']!.messages.keys.toSet(),
          );
          imports[pack.locale] = pack;
        }
        if (imports.length > 20) {
          throw const FormatException('Too many saved languages.');
        }
        if (!{...builtins, ...imports}.containsKey(value['selected'])) {
          throw const FormatException('Saved language is unavailable.');
        }
        result._imported = imports;
        result._selected = value['selected'] as String;
      }
    } catch (_) {
      result.loadWarning = 'Saved language settings could not be loaded. Built-in languages are available.';
    }
    return result;
  }

  String text(String source, [Map<String, Object> values = const {}]) {
    var result =
        _imported[_selected]?.messages[source] ??
        _builtins[_selected]?.messages[source] ??
        source;
    // A single replacement pass prevents path values containing braces from
    // being interpreted as other placeholders.
    result = result.replaceAllMapped(
      RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}'),
      (match) => values[match.group(1)]?.toString() ?? match.group(0)!,
    );
    return result;
  }

  Locale get frameworkLocale {
    final parts = selected.split('-');
    final script = parts.skip(1).where((p) => p.length == 4).firstOrNull;
    final region = parts
        .skip(1)
        .where((p) => p.length == 2 || p.length == 3 && int.tryParse(p) != null)
        .firstOrNull;
    final locale = Locale.fromSubtags(
      languageCode: parts.first,
      scriptCode: script,
      countryCode: region,
    );
    return GlobalMaterialLocalizations.delegate.isSupported(locale)
        ? locale
        : const Locale('en');
  }

  Future<void> _save(String selected, Map<String, LanguagePack> imported) =>
      store.write(
        jsonEncode({
          'schemaVersion': 1,
          'selected': selected,
          'packs': imported.values.map((p) => p.toJson()).toList(),
        }),
      );

  Future<void> select(String locale) async {
    if (!packs.containsKey(locale)) {
      throw const FormatException('Unknown language.');
    }
    await _save(locale, _imported);
    _selected = locale;
    notifyListeners();
  }

  Future<void> importJson(String source) async {
    final pack = LanguagePack.parse(
      source,
      knownKeys: _builtins['en']!.messages.keys.toSet(),
    );
    final imports = {..._imported, pack.locale: pack};
    if (imports.length > 20) {
      throw const FormatException(
        'At most 20 imported languages are supported.',
      );
    }
    await _save(pack.locale, imports);
    _imported = imports;
    _selected = pack.locale;
    notifyListeners();
  }
}
