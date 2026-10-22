import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// 커버 이미지를 칸(정사각형)에 어떻게 놓을지: 칸을 채운(cover) 그림을 [scale]배로 키우고,
/// 중심을 칸 한 변의 [dx] · [dy]배만큼 옮기고, 중심을 기준으로 [rotation]도(시계 방향) 돌린다.
/// 기본값은 가운데 맞춤 그대로. 그림이 칸을 다 덮지 못하면 빈 곳은 검정으로 보인다.
class CoverTransform extends Equatable {
  const CoverTransform({
    this.scale = 1,
    this.dx = 0,
    this.dy = 0,
    this.rotation = 0,
  });

  static const identity = CoverTransform();
  static const minScale = 0.2;
  static const maxScale = 5.0;

  /// 중심을 칸 밖으로 옮길 수 있는 한도 (칸 한 변의 배수). 그림을 아주 잃어버리지 않게 한다.
  static const maxOffset = 1.0;

  final double scale;
  final double dx;
  final double dy;

  /// 시계 방향 도(°). -180 ~ 180.
  final double rotation;

  bool get isIdentity => scale == 1 && dx == 0 && dy == 0 && rotation == 0;

  /// 배율 · 위치 · 각도를 허용 범위 안으로 맞춘다.
  CoverTransform clamped() {
    var r = rotation % 360;
    if (r > 180) r -= 360;
    if (r < -180) r += 360;
    return CoverTransform(
      scale: scale.clamp(minScale, maxScale),
      dx: dx.clamp(-maxOffset, maxOffset),
      dy: dy.clamp(-maxOffset, maxOffset),
      rotation: r,
    );
  }

  /// 가로 / 세로가 [aspect]인 그림을 칸(한 변 = 1)에 놓는 모양: 중심 ([cx], [cy]),
  /// 돌리기 전의 크기 [w] × [h], 시계 방향 [radians].
  ({double cx, double cy, double w, double h, double radians}) placement(
    double aspect,
  ) {
    final t = clamped();
    final fw = aspect >= 1 ? aspect : 1.0;
    final fh = aspect >= 1 ? 1.0 : 1 / aspect;
    return (
      cx: .5 + t.dx,
      cy: .5 + t.dy,
      w: fw * t.scale,
      h: fh * t.scale,
      radians: t.rotation * math.pi / 180,
    );
  }

  @override
  List<Object?> get props => [scale, dx, dy, rotation];
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
