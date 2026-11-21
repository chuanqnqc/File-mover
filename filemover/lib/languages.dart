import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

class WindowsLanguageStore {
  WindowsLanguageStore({File? settings, File? legacy})
    : settings = settings ?? File('$_directory\\locale.txt'),
      legacy = legacy ?? File('$_directory\\languages.json');

  static String get _directory =>
      '${Platform.environment['LOCALAPPDATA']}\\FileMover';
  final File settings;
  final File legacy;

  Future<String?> read() async {
    if (await settings.exists()) return (await settings.readAsString()).trim();
    // The legacy file is used only to recover the selected locale.
    if (!await legacy.exists()) return null;
    final value = jsonDecode(await legacy.readAsString());
    if (value is Map &&
        value['schemaVersion'] == 1 &&
        value['selected'] is String) {
      return value['selected'] as String;
    }
    throw const FormatException('Invalid saved language preference.');
  }

  Future<void> write(String locale) async {
    await settings.parent.create(recursive: true);
    final temporary = File(
      '${settings.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await temporary.writeAsString(locale, flush: true);
    await temporary.rename(settings.path);
  }
}

class AppLanguages extends ChangeNotifier {
  AppLanguages.english() : _selected = 'en', _store = null;
  AppLanguages._(this._selected, this._store);

  static const names = {'en': 'English', 'zh': '简体中文'};
  final WindowsLanguageStore? _store;
  String _selected;
  bool loadWarning = false;
  String get selected => _selected;
  Locale get locale => Locale(selected);

  static Future<AppLanguages> load({
    required WindowsLanguageStore store,
    String systemLocale = 'en',
  }) async {
    final fallback = systemLocale.toLowerCase().split('-').first == 'zh'
        ? 'zh'
        : 'en';
    final languages = AppLanguages._(fallback, store);
    try {
      languages._selected = switch (await store.read()) {
        'en' => 'en',
        'zh' || 'zh-Hans' => 'zh',
        _ => fallback,
      };
    } catch (_) {
      languages.loadWarning = true;
    }
    return languages;
  }

  Future<void> select(String locale) async {
    if (_selected == locale) return;
    if (!names.containsKey(locale)) throw ArgumentError.value(locale, 'locale');
    await _store?.write(locale);
    _selected = locale;
    loadWarning = false;
    notifyListeners();
  }
}
