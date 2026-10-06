import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';

void main() {
  test('기본값은 가운데를 정사각형으로 채운다', () {
    final r = CoverTransform.identity.visibleRect(1600, 900);
    expect(r.side, closeTo(900, 1e-9));
    expect(r.left, closeTo(350, 1e-9));
    expect(r.top, closeTo(0, 1e-9));
  });

  test('확대하면 보이는 영역이 줄고 가운데를 유지한다', () {
    final r = const CoverTransform(scale: 2).visibleRect(1000, 1000);
    expect(r.side, closeTo(500, 1e-9));
    expect(r.left, closeTo(250, 1e-9));
    expect(r.top, closeTo(250, 1e-9));
  });

  test('그림을 오른쪽으로 끌면 왼쪽 부분이 보인다', () {
    final r = const CoverTransform(scale: 2, dx: .5).visibleRect(1000, 1000);
    expect(r.left, closeTo(0, 1e-9));
  });

  test('범위를 넘으면 빈 곳이 보이지 않게 맞춘다', () {
    final t = const CoverTransform(scale: 99, dx: 9, dy: -9).clamped(1);
    expect(t.scale, CoverTransform.maxScale);
    expect(t.dx, closeTo((CoverTransform.maxScale - 1) / 2, 1e-9));
    expect(t.dy, closeTo(-(CoverTransform.maxScale - 1) / 2, 1e-9));
    // 배율 1이고 정사각형이면 옮길 여지가 없다.
    expect(const CoverTransform(dx: .4).clamped(1), CoverTransform.identity);
    // 가로로 긴 그림은 배율 1에서도 좌우로 옮길 수 있다.
    expect(const CoverTransform(dx: .1).clamped(16 / 9).dx, closeTo(.1, 1e-9));
  });
}
