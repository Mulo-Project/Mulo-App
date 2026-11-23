import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(AppPalette.defaultDark),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('시간 초과 안내는 연결 문제와 다른 문구와 다시 시도 버튼을 보인다', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(EmptyState.timeout(onRetry: () => retried++)),
    );
    expect(find.text('응답이 너무 오래 걸려요'), findsOneWidget);
    expect(find.text('네트워크 연결이 필요해요'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    expect(retried, 1);
  });

  testWidgets('onRetry가 없으면 버튼이 없다', (tester) async {
    await tester.pumpWidget(_host(const EmptyState.timeout()));
    expect(find.text('다시 시도'), findsNothing);
  });
}
