// Manual visual checkpoint; never runs against the API or database.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'groupon_preview_test.dart' show loadPreviewFonts;
import 'hybrid_checkpoint/components.dart';

Widget checkpointHost(Widget screen, GlobalKey key,
    {bool dark = false, double scale = 1}) {
  final base = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
  final font = WidgetStateProperty.all(
      const TextStyle(fontFamily: 'Roboto', fontSize: 14));
  return MaterialApp(
      theme: base.copyWith(
          textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
          appBarTheme: base.appBarTheme.copyWith(
              titleTextStyle: base.appBarTheme.titleTextStyle
                  ?.copyWith(fontFamily: 'Roboto')),
          textButtonTheme: TextButtonThemeData(
              style: base.textButtonTheme.style?.copyWith(textStyle: font)),
          filledButtonTheme: FilledButtonThemeData(
              style: base.filledButtonTheme.style?.copyWith(textStyle: font)),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: base.outlinedButtonTheme.style?.copyWith(textStyle: font)),
          chipTheme: base.chipTheme.copyWith(
              labelStyle:
                  base.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto')),
          navigationBarTheme: base.navigationBarTheme.copyWith(
              labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontFamily: 'Roboto', fontSize: 12)))),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(key: key, child: screen));
}

Future<void> capture(
    WidgetTester tester, GlobalKey key, String filename) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('design-preview/hybrid-checkpoint')
      ..createSync(recursive: true);
    File('${dir.path}/$filename.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    img.dispose();
  });
}

void main() {
  testWidgets(
      'render proposed Discover and Details without production integration',
      (tester) async {
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final large in [false, true]) {
        tester.view.physicalSize =
            large ? const Size(320, 760) : const Size(390, 844);
        for (final detail in [false, true]) {
          final key = GlobalKey();
          final name =
              '${detail ? 'details' : 'discover'}-${dark ? 'dark' : 'light'}-${large ? '320-large' : '390'}';
          await tester.pumpWidget(checkpointHost(
              detail ? const CheckpointDetails() : const CheckpointDiscover(),
              key,
              dark: dark,
              scale: large ? 2 : 1));
          await tester.pumpAndSettle();
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: name);
          await capture(tester, key, name);
          {
            await tester.drag(
                find
                    .descendant(
                        of: find
                            .byType(detail
                                ? SingleChildScrollView
                                : CustomScrollView)
                            .first,
                        matching: find.byType(Scrollable))
                    .first,
                const Offset(0, -460));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$name scrolled');
            await capture(tester, key, '$name-scrolled');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      tester.view.physicalSize = const Size(390, 2500);
      final key = GlobalKey();
      await tester.pumpWidget(
          checkpointHost(const CheckpointDiscover(), key, dark: dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(
          tester, key, 'discover-${dark ? 'dark' : 'light'}-extended');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets(
      'prototype composes category and online filters without physical distance',
      (tester) async {
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(checkpointHost(const CheckpointDiscover(), GlobalKey()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Essentials'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Online'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('Save LKR 500'), findsOneWidget);
    expect(find.textContaining('from selected area'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
