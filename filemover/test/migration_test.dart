import 'package:filemover/main.dart';
import 'package:filemover/migration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakeService implements MigrationService {
  final calls = <String>[];
  List<JsonMap> history = [];
  bool fail = false;
  @override
  Future<String?> pickFolder() async => r'C:\Example';
  @override
  Future<void> cancel() async {
    calls.add('cancel');
  }

  @override
  Future<dynamic> run(
    String action, {
    String? source,
    String? parent,
    String? id,
    void Function(JsonMap)? onProgress,
  }) async {
    calls.add(action);
    if (action == 'preflight' || action == 'undoPreflight') {
      if (fail) throw const MigrationException('Insufficient disk space');
      return {
        'source': source ?? r'D:\Moved\Example',
        'parent': parent ?? r'C:\Games',
        'destination': r'D:\Moved\Example',
        'files': 2,
        'bytes': 1024,
        'required': 268436480,
        'free': 1000000000,
      };
    }
    if (action == 'recover') history = [];
    return history;
  }
}

Future<void> checkFolders(WidgetTester tester, FakeService service) async {
  await tester.pumpWidget(MyApp(service: service));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), r'C:\Games\Example');
  await tester.enterText(find.byType(TextField).at(1), r'D:\Moved');
  await tester.pump();
  await tester.tap(find.text('Check folders'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('move requires explicit second confirmation and acknowledgment', (
    tester,
  ) async {
    final service = FakeService();
    await checkFolders(tester, service);
    await tester.tap(find.text('Apply move'));
    await tester.pumpAndSettle();
    expect(find.text('Double-check migration'), findsOneWidget);
    expect(service.calls, isNot(contains('move')));
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm and move'),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and move'));
    await tester.pumpAndSettle();
    expect(service.calls.where((c) => c == 'move').length, 1);
  });

  testWidgets('cancel confirmation does not move files', (tester) async {
    final service = FakeService();
    await checkFolders(tester, service);
    await tester.tap(find.text('Apply move'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, isNot(contains('move')));
  });

  testWidgets('editing paths invalidates preflight', (tester) async {
    final service = FakeService();
    await checkFolders(tester, service);
    await tester.enterText(find.byType(TextField).at(1), r'E:\Other');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply move'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('validation failure is visible and prevents moving', (
    tester,
  ) async {
    final service = FakeService()..fail = true;
    await checkFolders(tester, service);
    await tester.ensureVisible(find.text('Insufficient disk space'));
    expect(find.text('Insufficient disk space'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply move'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('unfinished journal blocks new moves and offers recovery', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = FakeService()
      ..history = [
        {
          'id': 'test',
          'source': r'C:\Games\Example',
          'destination': r'D:\Moved\Example',
          'state': 'copying',
          'direction': 'move',
          'message': '',
          'started': 'today',
        },
      ];
    await tester.pumpWidget(MyApp(service: service));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );
    await tester.scrollUntilVisible(
      find.text('Recover original location'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Recover original location'));
    await tester.pumpAndSettle();
    expect(service.calls, contains('recover'));
  });

  testWidgets('undo also requires second confirmation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = FakeService()
      ..history = [
        {
          'id': 'test',
          'source': r'C:\Games\Example',
          'destination': r'D:\Moved\Example',
          'state': 'complete',
          'direction': 'move',
          'message': '',
          'started': 'today',
        },
      ];
    await tester.pumpWidget(MyApp(service: service));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Undo migration'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Undo migration'));
    await tester.pumpAndSettle();
    expect(find.text('Double-check undo'), findsOneWidget);
    expect(service.calls, contains('undoPreflight'));
    expect(service.calls, isNot(contains('undo')));
  });
}
