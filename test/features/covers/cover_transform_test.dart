import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';

void main() {
  test('기본값은 칸을 가운데로 채운다', () {
    final p = CoverTransform.identity.placement(16 / 9);
    expect(p.cx, closeTo(.5, 1e-9));
    expect(p.cy, closeTo(.5, 1e-9));
    expect(p.w, closeTo(16 / 9, 1e-9));
    expect(p.h, closeTo(1, 1e-9));
    expect(p.radians, 0);
  });

  test('확대하면 그림이 커지고 중심은 그대로다', () {
    final p = const CoverTransform(scale: 2).placement(1);
    expect(p.w, closeTo(2, 1e-9));
    expect(p.h, closeTo(2, 1e-9));
    expect(p.cx, closeTo(.5, 1e-9));
  });

  test('세로로 긴 그림은 가로가 칸에 맞는다', () {
    final p = CoverTransform.identity.placement(9 / 16);
    expect(p.w, closeTo(1, 1e-9));
    expect(p.h, closeTo(16 / 9, 1e-9));
  });

  test('축소하면 칸보다 작아져 빈 곳이 생기고, 옮기면 중심이 따라간다', () {
    final p = const CoverTransform(scale: .5, dx: .25, dy: -.25).placement(1);
    expect(p.w, closeTo(.5, 1e-9));
    expect(p.cx, closeTo(.75, 1e-9));
    expect(p.cy, closeTo(.25, 1e-9));
  });

  test('회전은 도를 라디안으로 바꾼다', () {
    final p = const CoverTransform(rotation: 90).placement(1);
    expect(p.radians, closeTo(1.5707963267948966, 1e-9));
  });

  test('범위를 넘는 값은 허용 범위로 맞춘다', () {
    final t = const CoverTransform(
      scale: 99,
      dx: 9,
      dy: -9,
      rotation: 270,
    ).clamped();
    expect(t.scale, CoverTransform.maxScale);
    expect(t.dx, CoverTransform.maxOffset);
    expect(t.dy, -CoverTransform.maxOffset);
    expect(t.rotation, closeTo(-90, 1e-9));
    expect(const CoverTransform(scale: .01).clamped().scale, .2);
  });

  test('기본값만 identity다', () {
    expect(CoverTransform.identity.isIdentity, isTrue);
    expect(const CoverTransform(rotation: 1).isIdentity, isFalse);
  });
}
