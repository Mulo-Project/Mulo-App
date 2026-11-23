import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/cover/cover_paint.dart';
import '../domain/entities/cover_art.dart';

/// [base] 이미지를 [transform]대로 확대 · 이동해 정사각형으로 잘라 낸 이미지.
/// 어디서든 평범한 [ImageProvider]처럼 쓸 수 있어(목록 · 카드 · 플레이어 · 테마 색 추출),
/// 화면마다 확대 · 위치를 따로 처리하지 않아도 된다.
class CoverImageProvider extends ImageProvider<CoverImageProvider> {
  const CoverImageProvider(this.base, this.transform);

  /// 잘라 낼 출력 한 변 (픽셀). 목록 칸보다 크고 큰 플레이어 커버에도 충분하다.
  static const outputSide = 512;

  final ImageProvider base;
  final CoverTransform transform;

  @override
  Future<CoverImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CoverImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    _crop().then((image) => ImageInfo(image: image)),
  );

  Future<ui.Image> _crop() async {
    final source = await _resolve();
    try {
      final recorder = ui.PictureRecorder();
      paintCover(ui.Canvas(recorder), outputSide.toDouble(), source, transform);
      final picture = recorder.endRecording();
      final out = await picture.toImage(outputSide, outputSide);
      picture.dispose();
      return out;
    } finally {
      source.dispose();
    }
  }

  /// [base]의 첫 프레임. 읽지 못하면 오류를 던진다.
  Future<ui.Image> _resolve() {
    final done = Completer<ui.Image>();
    final stream = base.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) done.complete(info.image.clone());
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!done.isCompleted) done.completeError(error, stack);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  @override
  bool operator ==(Object other) =>
      other is CoverImageProvider &&
      other.base == base &&
      other.transform == transform;

  @override
  int get hashCode => Object.hash(base, transform);
}
