import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:music_download_play_app/core/cache/cached_web_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/presentation/bloc/cover_cubit.dart';
import 'package:music_download_play_app/features/covers/presentation/bloc/cover_web_cubit.dart';
import 'package:music_download_play_app/features/covers/presentation/cover_image_provider.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isWebImageUrl은 http(s) 주소만 받는다', () {
    expect(isWebImageUrl('https://x.test/a.jpg'), isTrue);
    expect(isWebImageUrl(' http://x.test/a '), isTrue);
    expect(isWebImageUrl('아이유 앨범'), isFalse);
    expect(isWebImageUrl('ftp://x.test/a.jpg'), isFalse);
    expect(isWebImageUrl('/tmp/a.png'), isFalse);
  });

  group('CoverWebCubit', () {
    test('검색 결과의 대표 이미지 주소만 모은다', () async {
      final engine = FakeDownloaderEngine(
        pages: const [
          SearchPage(
            items: [
              MediaHit(
                id: 'a',
                title: 'A',
                url: 'https://y.test/a',
                thumbnailUrl: 'https://i.test/a.jpg',
              ),
              MediaHit(id: 'b', title: 'B', url: 'https://y.test/b'),
            ],
            hasNext: false,
          ),
        ],
      );
      final c = CoverWebCubit(SearchTracks(engine));
      addTearDown(c.close);
      await c.search('  앨범 아트 ');
      expect(c.state.status, CoverWebStatus.loaded);
      expect(c.state.images, ['https://i.test/a.jpg']);
      expect(engine.searches.single.$1, '앨범 아트');
    });

    test('검색이 실패하면 failed', () async {
      final c = CoverWebCubit(
        SearchTracks(
          FakeDownloaderEngine(
            error: const EngineException(EngineFailure.unavailable),
          ),
        ),
      );
      addTearDown(c.close);
      await c.search('x');
      expect(c.state.status, CoverWebStatus.failed);
    });

    test('빈 검색어는 무시한다', () async {
      final engine = FakeDownloaderEngine();
      final c = CoverWebCubit(SearchTracks(engine));
      addTearDown(c.close);
      await c.search('   ');
      expect(c.state.status, CoverWebStatus.idle);
      expect(engine.searches, isEmpty);
    });
  });

  group('imageOfCoverArt', () {
    test('손대지 않은 그림은 원본 그대로, 옮긴 그림은 잘라 내는 이미지', () {
      expect(
        imageOfCoverArt(const CoverArt.web('https://x.test/a.jpg')),
        isA<CachedWebImage>(),
      );
      expect(
        imageOfCoverArt(
          const CoverArt.web(
            'https://x.test/a.jpg',
            transform: CoverTransform(scale: 2),
          ),
        ),
        isA<CoverImageProvider>(),
      );
    });

    test('CoverImageProvider는 확대 · 위치대로 정사각형으로 잘라 낸다', () async {
      // 4x2 그림: 왼쪽 절반 빨강, 오른쪽 절반 파랑.
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 2, 2),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(2, 0, 2, 2),
        ui.Paint()..color = const ui.Color(0xFF0000FF),
      );
      final src = await recorder.endRecording().toImage(4, 2);
      final bytes = (await src.toByteData(format: ui.ImageByteFormat.png))!;
      final base = MemoryImage(bytes.buffer.asUint8List());

      Future<ui.Color> centerOf(CoverTransform t) async {
        final stream = CoverImageProvider(
          base,
          t,
        ).resolve(ImageConfiguration.empty);
        final info = await _first(stream);
        expect(info.image.width, CoverImageProvider.outputSide);
        expect(info.image.height, CoverImageProvider.outputSide);
        final data = (await info.image.toByteData())!;
        const mid = CoverImageProvider.outputSide ~/ 2;
        final i = (mid * CoverImageProvider.outputSide + mid) * 4;
        return ui.Color.fromARGB(
          255,
          data.getUint8(i),
          data.getUint8(i + 1),
          data.getUint8(i + 2),
        );
      }

      // 가운데 맞춤이면 가운데 정사각형(왼쪽 반 + 오른쪽 반) 한가운데는 경계라 건너뛰고,
      // 확대한 뒤 좌우로 옮긴 가운데가 각 색이어야 한다.
      final left = await centerOf(const CoverTransform(scale: 2, dx: .5));
      final right = await centerOf(const CoverTransform(scale: 2, dx: -.5));
      expect(left.r, greaterThan(.9));
      expect(right.b, greaterThan(.9));
    });
  });
}

Future<ImageInfo> _first(ImageStream stream) {
  final done = Completer<ImageInfo>();
  late final ImageStreamListener l;
  l = ImageStreamListener(
    (info, _) {
      if (!done.isCompleted) done.complete(info);
      stream.removeListener(l);
    },
    onError: (e, st) {
      if (!done.isCompleted) done.completeError(e, st);
    },
  );
  stream.addListener(l);
  return done.future;
}
