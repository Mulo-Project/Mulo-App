import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/covers/presentation/cover_controller.dart';

import '../../helpers/fakes.dart';

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

ProviderContainer _container(
  CoverImagePicker picker, [
  MemoryCoverStore? store,
]) => ProviderContainer(
  overrides: [
    coverImagePickerProvider.overrideWithValue(picker),
    coverStoreProvider.overrideWithValue(store ?? MemoryCoverStore()),
  ],
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

  test('clear는 기본 이미지로 되돌리고 저장소에서도 지운다', () async {
    final store = MemoryCoverStore();
    final c = _container(_FakePicker('/tmp/a.png'), store);
    addTearDown(c.dispose);
    final ctrl = c.read(coverProvider.notifier);
    await ctrl.pickFor(CoverKey.track('t01'));
    await ctrl.pickFor(CoverKey.track('t02'));
    await ctrl.clear(CoverKey.track('t01'));
    expect(c.read(coverProvider).keys, [CoverKey.track('t02')]);
    expect(store.saved.keys, [CoverKey.track('t02')]);
  });

  test('시작할 때 저장된 커버를 불러온다', () async {
    final store = MemoryCoverStore()..saved['playlist:Focus'] = '/tmp/f.png';
    final c = _container(_FakePicker(null), store);
    addTearDown(c.dispose);
    c.read(coverProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(coverProvider), {'playlist:Focus': '/tmp/f.png'});
  });

  testWidgets('재생목록 카드의 이미지 버튼으로 사진을 고른다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final picker = _FakePicker('/tmp/cover.png');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appTestOverrides(),
          coverImagePickerProvider.overrideWithValue(picker),
        ],
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
