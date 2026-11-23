import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/presentation/widgets/cover_web_browser.dart';

void main() {
  test('이미지 상세 주소에서 원본 이미지 주소를 읽는다', () {
    expect(
      originalImageUrlOf(
        'https://www.bing.com/images/search?q=a&view=detailV2'
        '&mediaurl=https%3a%2f%2fexample.com%2fcover.jpg',
      ),
      'https://example.com/cover.jpg',
    );
    expect(
      originalImageUrlOf(
        'https://www.google.com/imgres?imgurl=https%3A%2F%2Fexample.com%2Fa.png',
      ),
      'https://example.com/a.png',
    );
    expect(
      originalImageUrlOf('https://www.bing.com/images/search?q=a'),
      isNull,
    );
    expect(originalImageUrlOf('https://x.com/?mediaurl=javascript:1'), isNull);
  });
}
