import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

Widget _host(SectionLayoutController? layout) {
  Widget body = Column(
    children: const [
      SectionCard(
        title: '다운로드',
        initiallyExpanded: true,
        children: [
          SettingRow(title: '저장 위치', description: '음악 폴더'),
          SettingRow(title: '기본 포맷'),
        ],
      ),
      SectionCard(
        title: '보안',
        children: [
          SettingRow(title: '앱 잠금'),
          SettingRow(title: '알림에 곡 정보 숨기기'),
        ],
      ),
    ],
  );
  if (layout != null) {
    body = SectionLayoutScope(controller: layout, child: body);
  }
  return MaterialApp(
    theme: buildAppTheme(AppPalette.defaultDark),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: body)),
  );
}

void main() {
  testWidgets('범위가 없으면 묶음은 늘 펼쳐져 있다', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(find.text('저장 위치'), findsOneWidget);
    expect(find.text('앱 잠금'), findsOneWidget);
  });

  testWidgets('접힌 묶음은 제목만 보이고, 제목을 누르면 펼쳐졌다 접힌다', (tester) async {
    final layout = SectionLayoutController();
    addTearDown(layout.dispose);
    await tester.pumpWidget(_host(layout));
    expect(find.text('저장 위치'), findsOneWidget);
    expect(find.text('보안'), findsOneWidget);
    expect(find.text('앱 잠금'), findsNothing);

    await tester.tap(find.text('보안'));
    await tester.pumpAndSettle();
    expect(find.text('앱 잠금'), findsOneWidget);

    await tester.tap(find.text('다운로드'));
    await tester.pumpAndSettle();
    expect(find.text('저장 위치'), findsNothing);
  });

  testWidgets('검색하면 맞는 줄만 남고 접힌 묶음도 펼쳐 보인다', (tester) async {
    final layout = SectionLayoutController();
    addTearDown(layout.dispose);
    await tester.pumpWidget(_host(layout));

    layout.setQuery('잠금');
    await tester.pumpAndSettle();
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('알림에 곡 정보 숨기기'), findsNothing);
    // 맞는 줄이 없는 묶음은 제목째 사라진다.
    expect(find.text('다운로드'), findsNothing);

    // 설명에 들어 있는 말로도 찾는다.
    layout.setQuery('음악');
    await tester.pumpAndSettle();
    expect(find.text('저장 위치'), findsOneWidget);
    expect(find.text('기본 포맷'), findsNothing);
    expect(find.text('보안'), findsNothing);

    // 제목이 맞으면 묶음 전체.
    layout.setQuery('보안');
    await tester.pumpAndSettle();
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('알림에 곡 정보 숨기기'), findsOneWidget);

    // 지우면 원래 접힘 상태로 돌아간다.
    layout.setQuery('');
    await tester.pumpAndSettle();
    expect(find.text('앱 잠금'), findsNothing);
    expect(find.text('저장 위치'), findsOneWidget);
  });
}
