import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/covers/presentation/cover_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePicker implements CoverImagePicker {
  _FakePicker(this.result);

  final String? result;
  int calls = 0;

  @override
  Future<String?> pickImage() async {
    calls++;
    return result;
  }
}

ProviderContainer _container(CoverImagePicker picker) => ProviderContainer(
  overrides: [coverImagePickerProvider.overrideWithValue(picker)],
);

void main() {
  test('pickFor는 고른 경로를 커버로 저장한다', () async {
    final c = _container(_FakePicker('/tmp/a.png'));
    addTearDown(c.dispose);
    final ok = await c
        .read(coverProvider.notifier)
        .pickFor(CoverKey.track('t01'));
    expect(ok, isTrue);
    expect(c.read(coverProvider)[CoverKey.track('t01')], '/tmp/a.png');
  });

  test('취소하면 바뀌지 않는다', () async {
    final c = _container(_FakePicker(null));
    addTearDown(c.dispose);
    final ok = await c
        .read(coverProvider.notifier)
        .pickFor(CoverKey.playlist('Focus'));
    expect(ok, isFalse);
    expect(c.read(coverProvider), isEmpty);
  });

  test('clear는 기본 이미지로 되돌린다', () {
    final c = _container(_FakePicker(null));
    addTearDown(c.dispose);
    c.read(coverProvider.notifier)
      ..set(CoverKey.track('t01'), '/tmp/a.png')
      ..set(CoverKey.track('t02'), '/tmp/b.png')
      ..clear(CoverKey.track('t01'));
    expect(c.read(coverProvider).keys, [CoverKey.track('t02')]);
  });

  testWidgets('재생목록 카드의 이미지 버튼으로 사진을 고른다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final picker = _FakePicker('/tmp/cover.png');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coverImagePickerProvider.overrideWithValue(picker)],
        child: const MusicApp(initialLocation: Routes.playlists),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('커버 이미지 바꾸기').first);
    await tester.pumpAndSettle();
    expect(find.text('커버 이미지'), findsOneWidget);

    await tester.tap(find.text('사진에서 고르기'));
    await tester.pumpAndSettle();
    expect(picker.calls, 1);
    expect(find.text('커버 이미지'), findsNothing);
  });
}
