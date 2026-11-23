import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(AppPalette.defaultDark),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('blur를 0으로 주면 유리 면이 흐림 층을 만들지 않는다', (tester) async {
    await tester.pumpWidget(
      _host(const GlassSurface(blur: 0, child: SizedBox.square(dimension: 40))),
    );
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(
      _host(const GlassSurface(child: SizedBox.square(dimension: 40))),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('목록 줄 버튼은 흐림 층 없이 작게 그려지고 눌린다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        RowIconButton(
          icon: Icons.download,
          tooltip: '받기',
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.getSize(find.byType(RowIconButton)),
      const Size.square(AppSizes.rowButton),
    );
    await tester.tap(find.byType(RowIconButton));
    expect(taps, 1);
  });

  testWidgets('busy면 줄 버튼 · 알약 버튼에 돌아가는 표시가 보인다', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            RowIconButton(icon: Icons.headphones, tooltip: '듣기', busy: true),
            PillButton(label: '준비 중', icon: Icons.headphones, busy: true),
          ],
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(find.byIcon(Icons.headphones), findsNothing);
  });

  testWidgets('ArtworkBox는 큰 이미지를 칸 크기로 줄여 디코딩한다', (tester) async {
    await tester.pumpWidget(
      _host(
        const ArtworkBox(
          image: NetworkImage('https://example.invalid/thumb.jpg'),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    final resize = image as ResizeImage;
    // 테스트 기본 화면 배율 3.0 × 칸 48 × 2.
    expect(resize.width, 288);
    expect(resize.height, 288);
    expect(resize.policy, ResizeImagePolicy.fit);
  });
}
