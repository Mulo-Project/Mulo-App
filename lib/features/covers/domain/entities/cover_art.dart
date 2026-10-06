import 'package:equatable/equatable.dart';

/// 커버 이미지를 어떻게 잘라 보여 줄지: 칸을 채운 그림을 [scale]배로 키우고
/// 칸 한 변의 [dx] · [dy]배만큼 옮긴다. 기본값은 가운데 맞춤 그대로.
class CoverTransform extends Equatable {
  const CoverTransform({this.scale = 1, this.dx = 0, this.dy = 0});

  static const identity = CoverTransform();
  static const minScale = 1.0;
  static const maxScale = 5.0;

  final double scale;
  final double dx;
  final double dy;

  bool get isIdentity => scale == 1 && dx == 0 && dy == 0;

  /// 칸에 가장 알맞게 채운(cover) 그림의 가로 · 세로 (칸 한 변 = 1).
  static ({double w, double h}) _filled(double aspect) =>
      aspect >= 1 ? (w: aspect, h: 1) : (w: 1, h: 1 / aspect);

  /// 그림이 칸 밖으로 비어 보이지 않도록 배율 · 위치를 범위 안으로 맞춘다.
  /// [aspect]는 그림의 가로 / 세로.
  CoverTransform clamped(double aspect) {
    final s = scale.clamp(minScale, maxScale);
    final f = _filled(aspect);
    final mx = (f.w * s - 1) / 2;
    final my = (f.h * s - 1) / 2;
    return CoverTransform(
      scale: s,
      dx: dx.clamp(-mx, mx),
      dy: dy.clamp(-my, my),
    );
  }

  /// 가로 [iw] 세로 [ih] 픽셀 그림에서 칸에 보이는 정사각형 영역 (그림 픽셀 기준).
  ({double left, double top, double side}) visibleRect(double iw, double ih) {
    final t = clamped(iw / ih);
    final f = _filled(iw / ih);
    final w = f.w * t.scale;
    final h = f.h * t.scale;
    // 그림 중심이 (0.5 + dx, 0.5 + dy)에 있을 때 칸 [0, 1]에 해당하는 구간.
    final left = (w / 2 - .5 - t.dx) / w * iw;
    final top = (h / 2 - .5 - t.dy) / h * ih;
    return (left: left, top: top, side: 1 / w * iw);
  }

  @override
  List<Object?> get props => [scale, dx, dy];
}

/// 곡 · 앨범 · 재생목록에 붙인 커버 이미지. 기기 사진이면 [path] (앱 폴더로 복사한 파일),
/// 웹 이미지면 [url] (파일을 복사하지 않고 주소만 기억한다). 둘 중 하나만 있다.
class CoverArt extends Equatable {
  const CoverArt.file(
    String this.path, {
    this.transform = CoverTransform.identity,
  }) : url = null;

  const CoverArt.web(
    String this.url, {
    this.transform = CoverTransform.identity,
  }) : path = null;

  final String? path;
  final String? url;
  final CoverTransform transform;

  bool get isWeb => url != null;

  CoverArt withTransform(CoverTransform t) => isWeb
      ? CoverArt.web(url!, transform: t)
      : CoverArt.file(path!, transform: t);

  @override
  List<Object?> get props => [path, url, transform];
}
