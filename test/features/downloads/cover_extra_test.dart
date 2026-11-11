import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/cover_tag_writer.dart';

void main() {
  test('coverExtra: 커버 색만 태그 글로 남기고, 주소 · 확대 · 위치는 쓰지 않는다', () {
    expect(coverExtra(0xFF112233), {'COVER_COLOR': 'ff112233'});
    expect(coverExtra(null), isEmpty);
  });

  test('parseCoverColor는 coverExtra가 쓴 값을 되읽는다 (키는 대소문자 구분 없음)', () {
    expect(parseCoverColor(coverExtra(0xFF00AAFF)), 0xFF00AAFF);
    expect(parseCoverColor({'cover_color': ' ff112233 '}), 0xFF112233);
    expect(parseCoverColor(const {}), isNull);
    expect(parseCoverColor({'cover_color': 'zz'}), isNull);
  });
}
