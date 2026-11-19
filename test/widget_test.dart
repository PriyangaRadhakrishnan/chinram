import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:chinram_app/main.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('chinram_test');
    Hive.init(tempDir.path);
    await Hive.openBox('auth_box');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App launches and displays Splash Screen text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ChinramApp(),
      ),
    );

    expect(find.text('ChinRam'), findsOneWidget);

    // Drain the delayed navigation timer of the Splash Screen
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
