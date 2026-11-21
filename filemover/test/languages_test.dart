import 'dart:io';

import 'package:filemover/languages.dart';
import 'package:filemover/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'migration_test.dart' show FakeService;

void main() {
  test(
    'preserves built-in preferences and ignores imported selections',
    () async {
      final dir = await Directory.systemTemp.createTemp('filemover-locale-');
      final settings = File('${dir.path}/locale.txt');
      final legacy = File('${dir.path}/languages.json');
      final store = WindowsLanguageStore(settings: settings, legacy: legacy);
      await legacy.writeAsString(
        '{"schemaVersion":1,"selected":"zh-Hans","packs":[]}',
      );
      final languages = await AppLanguages.load(store: store);
      expect(languages.selected, 'zh');
      await legacy.writeAsString(
        '{"schemaVersion":1,"selected":"es","packs":[]}',
      );
      expect((await AppLanguages.load(store: store)).selected, 'en');
      await languages.select('en');
      expect(
        (await AppLanguages.load(store: store, systemLocale: 'zh-CN')).selected,
        'en',
      );
    },
  );

  testWidgets(
    'language menu preserves entered paths and translates confirmation',
    (tester) async {
      final languages = AppLanguages.english();
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
              widget is CheckedPopupMenuItem<String> && widget.value == 'zh',
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
}
