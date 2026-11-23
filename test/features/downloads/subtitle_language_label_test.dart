import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/presentation/widgets/subtitle_language_label.dart';

void main() {
  test('언어 코드를 이름으로 바꾸고, 원어 자동 자막과 모르는 코드를 구분한다', () {
    expect(subtitleLanguageLabel('ko', korean: true), '한국어');
    expect(subtitleLanguageLabel('en-US', korean: false), 'English (US)');
    expect(subtitleLanguageLabel('ja-orig', korean: true), '일본어 (자동)');
    expect(subtitleLanguageLabel('xx', korean: true), 'xx');
  });
}
