import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/repositories/file_saved_detail_store.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';

void main() {
  test('상세 정보 글 파일에 설명 · 조회수 · 좋아요 · 올린 날 · 분류 · 채널이 들어간다', () {
    final text = formatSavedDetail(
      MediaHit(
        id: 'v',
        title: '곡',
        url: 'https://yt/v',
        uploader: '채널',
        viewCount: 1200,
        likeCount: 30,
        uploadedAt: DateTime(2026, 3, 5),
        categories: const ['Music'],
        description: '설명 글',
      ),
    );
    expect(text, contains('제목: 곡'));
    expect(text, contains('채널: 채널'));
    expect(text, contains('조회수: 1200'));
    expect(text, contains('좋아요: 30'));
    expect(text, contains('올린 날: 2026-03-05'));
    expect(text, contains('분류: Music'));
    expect(text, contains('설명:\n설명 글'));
  });
}
