import 'dart:convert';
import 'dart:io';

import 'package:filemover/languages.dart';
import 'package:filemover/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'migration_test.dart' show FakeService;

String pack({
  String locale = 'fr',
  String name = 'Français',
  String direction = 'ltr',
  Map<String, Object> messages = const {'Source folder': 'Dossier source'},
}) => jsonEncode({
  'schemaVersion': 1,
  'locale': locale,
  'name': name,
  'direction': direction,
  'messages': messages,
});

class FailingLanguageStore extends MemoryLanguageStore {
  @override
  Future<void> write(String value) async =>
      throw StateError('Disk unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Windows language settings replace existing files and reload after restart',
    () async {
      final base = await Directory('build').create(recursive: true);
      final temporary = await base.createTemp('language-settings-');
      try {
        final file = File('${temporary.path}/preferences.json');
        final store = WindowsLanguageStore(settings: file);
        final languages = await AppLanguages.load(store: store);
        await languages.select('zh-Hans');
        await languages.importJson(pack());
        final reloaded = await AppLanguages.load(
          store: WindowsLanguageStore(settings: file),
        );
        expect(reloaded.selected, 'fr');
        expect(reloaded.text('Source folder'), 'Dossier source');
        expect(temporary.listSync().length, 1);
      } finally {
        await temporary.delete(recursive: true);
      }
    },
  );

  test(
    'Chinese catalog covers the English template and matches placeholders',
    () async {
      final languages = await AppLanguages.load(
        store: MemoryLanguageStore(),
        systemLocale: 'zh-CN',
      );
      expect(languages.selected, 'zh-Hans');
      expect(languages.current.messages.keys.toSet(), languages.messageKeys);
      for (final entry in languages.current.messages.entries) {
        expect(
          LanguagePack.placeholders(entry.value),
          LanguagePack.placeholders(entry.key),
        );
      }
      expect(languages.text('Source folder'), '源文件夹');
      expect(
        languages.text('{count} files · {size} of data', {
          'count': 2,
          'size': '1 KiB',
        }),
        '2 个文件 · 数据大小 1 KiB',
      );
    },
  );

  test(
    'partial imported pack persists selection and falls back to English',
    () async {
      final store = MemoryLanguageStore();
      final languages = await AppLanguages.load(store: store);
      await languages.importJson(pack());
      expect(languages.selected, 'fr');
      expect(languages.text('Source folder'), 'Dossier source');
      expect(languages.text('Apply move'), 'Apply move');
      final reloaded = await AppLanguages.load(
        store: store,
        systemLocale: 'zh-CN',
      );
      expect(reloaded.selected, 'fr');
      expect(reloaded.text('Source folder'), 'Dossier source');
      await reloaded.select('zh-Hans');
      expect((await AppLanguages.load(store: store)).selected, 'zh-Hans');
    },
  );

  test(
    'import can override a builtin without losing its missing translations',
    () async {
      final languages = await AppLanguages.load(store: MemoryLanguageStore());
      await languages.importJson(
        pack(
          locale: 'zh-Hans',
          name: '自定义中文',
          messages: {'Source folder': '来源目录'},
        ),
      );
      expect(languages.text('Source folder'), '来源目录');
      expect(languages.text('Apply move'), '应用迁移');
      expect(languages.messageKeys, contains('Confirm and move'));
    },
  );

  test('malformed JSON, unknown keys, values, locale, and placeholders are rejected atomically', () async {
    final store = MemoryLanguageStore();
    final languages = await AppLanguages.load(store: store);
    for (final source in [
      '{',
      '[]',
      '{}',
      pack(locale: '../bad'),
      pack(name: ''),
      pack(direction: 'up'),
      pack(messages: {'Unknown key': 'text'}),
      pack(messages: {'Source folder': 5}),
      pack(messages: {'Source folder': ''}),
      pack(messages: {'Browse {label}': 'Browse {wrong}'}),
      pack(messages: {'Browse {label}': 'Browse'}),
      pack(messages: {'Source folder': 'Source {unexpected}'}),
      pack(messages: {}),
      ' ' * (maxLanguageBytes + 1),
    ]) {
      await expectLater(languages.importJson(source), throwsFormatException);
      expect(languages.selected, 'en');
      expect(languages.packs.length, 2);
      expect(store.contents, isNull);
    }
  });

  test('UTF-8 BOM accepted and placeholders are substituted in a single pass', () async {
    final languages = await AppLanguages.load(store: MemoryLanguageStore());
    await languages.importJson(
      '\uFEFF${pack(messages: {'{required} required · {free} available': '{free} / {required}'})}',
    );
    expect(
      languages.text('{required} required · {free} available', {
        'required': '{free}',
        'free': '10 GiB',
      }),
      '10 GiB / {free}',
    );
  });

  test(
    'unavailable framework locales use English widget localizations',
    () async {
      final languages = await AppLanguages.load(store: MemoryLanguageStore());
      await languages.importJson(pack(locale: 'zz', name: 'Custom'));
      expect(languages.frameworkLocale, const Locale('en'));
      expect(languages.text('Source folder'), 'Dossier source');
    },
  );

  test(
    'corrupt saved settings recover to builtin languages with a warning',
    () async {
      final store = MemoryLanguageStore()..contents = '{broken';
      final languages = await AppLanguages.load(
        store: store,
        systemLocale: 'zh-TW',
      );
      expect(languages.selected, 'zh-Hans');
      expect(languages.loadWarning, isNotNull);
      expect(store.contents, '{broken');
    },
  );

  test(
    'failed persistence leaves selection and imported catalog unchanged',
    () async {
      final languages = await AppLanguages.load(store: FailingLanguageStore());
      await expectLater(languages.select('zh-Hans'), throwsStateError);
      await expectLater(languages.importJson(pack()), throwsStateError);
      expect(languages.selected, 'en');
      expect(languages.packs.length, 2);
    },
  );

  testWidgets(
    'language menu preserves entered paths and translates confirmation',
    (tester) async {
      final languages = (await tester.runAsync(
        () => AppLanguages.load(store: MemoryLanguageStore()),
      ))!;
      await tester.pumpWidget(
        MyApp(service: FakeService(), languages: languages),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, r'C:\Games\Example');
      await tester.enterText(find.byType(TextField).at(1), r'D:\Moved');
      await tester.pump();
      await tester.tap(find.text('Check folders'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<String> &&
              widget.value == 'locale:zh-Hans',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('源文件夹'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        r'C:\Games\Example',
      );
      await tester.tap(find.text('应用迁移'));
      await tester.pumpAndSettle();
      expect(find.text('再次确认迁移'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认并迁移'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('JSON import menu activates a custom language', (tester) async {
    final store = MemoryLanguageStore()
      ..importContents = pack(
        messages: {'Source folder': 'Dossier source', 'Apply move': 'Déplacer'},
      );
    final languages = (await tester.runAsync(
      () => AppLanguages.load(store: store),
    ))!;
    await tester.pumpWidget(
      MyApp(service: FakeService(), languages: languages),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import language JSON…'));
    await tester.pumpAndSettle();
    expect(find.text('Dossier source'), findsOneWidget);
    expect(find.text('Déplacer'), findsOneWidget);
    expect(languages.selected, 'fr');
  });

  testWidgets('RTL imported pack changes layout direction', (tester) async {
    final languages = (await tester.runAsync(
      () => AppLanguages.load(store: MemoryLanguageStore()),
    ))!;
    await languages.importJson(
      pack(
        locale: 'ar',
        name: 'العربية',
        direction: 'rtl',
        messages: {'Source folder': 'المجلد المصدر'},
      ),
    );
    await tester.pumpWidget(
      MyApp(service: FakeService(), languages: languages),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(TextField).first)),
      TextDirection.rtl,
    );
    expect(find.text('المجلد المصدر'), findsOneWidget);
  });
}
