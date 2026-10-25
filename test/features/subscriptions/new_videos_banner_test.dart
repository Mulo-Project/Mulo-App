import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/widgets/new_videos_launcher.dart';
import 'package:music_download_play_app/l10n/app_localizations.dart';

Widget _host({
  required int? count,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) => MaterialApp(
  theme: buildAppTheme(AppPalette.defaultDark),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Stack(
      children: [
        NewVideosBanner(
          count: count,
          onOpen: onOpen ?? () {},
          onClose: onClose ?? () {},
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('새 영상 안내 줄: 수와 보기 · 닫기가 보이고, 누르면 각 동작을 한다', (tester) async {
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      _host(count: 3, onOpen: () => opened++, onClose: () => closed++),
    );
    await tester.pumpAndSettle();
    expect(find.text('구독 채널에 새 영상이 3개 있어요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-videos-banner-open')));
    await tester.tap(find.byKey(const ValueKey('new-videos-banner-close')));
    expect(opened, 1);
    expect(closed, 1);
  });

  testWidgets('새 영상이 없으면 안내 줄은 눌리지도 않는다 (화면 밖에 숨는다)', (tester) async {
    await tester.pumpWidget(_host(count: null));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byType(AnimatedSlide),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
  });
}
