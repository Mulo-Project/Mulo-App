import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/features/downloads/data/repositories/yt_dlp_video_save_repository.dart';
import 'package:music_app/features/downloads/domain/repositories/video_save_repository.dart';
import 'package:music_app/features/downloads/domain/usecases/download_usecases.dart';

class _Repo implements VideoSaveRepository {
  _Repo({this.fail = false});

  final bool fail;
  final saved = <VideoSaveRequest>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> save(VideoSaveRequest request) async {
    if (fail) throw const VideoSaveException('boom');
    saved.add(request);
  }
}

void main() {
  test('화질 선택자는 상한 이하 H.264+AAC를 먼저 찾고 합쳐진 형식으로 끝난다', () {
    final s = YtDlpVideoSaveRepository.selector(1080);
    expect(s, startsWith('bv*[height<=1080][vcodec^=avc1]+ba[ext=m4a]'));
    expect(s, endsWith('/b[height<=1080]/b'));
  });

  test('파일 이름에서 못 쓰는 글자를 뺀다', () {
    expect(YtDlpVideoSaveRepository.safeName('a/b: c*?"<>|d'), 'a b c d');
    expect(YtDlpVideoSaveRepository.safeName('  '), 'video');
    expect(YtDlpVideoSaveRepository.safeName('가' * 150).length, 100);
  });

  test('SaveVideo: 비어 있으면 받지 않고, 실패는 false', () async {
    final repo = _Repo();
    expect(
      await SaveVideo(repo)(const VideoSaveRequest(url: '', title: 't')),
      isFalse,
    );
    expect(repo.saved, isEmpty);
    expect(
      await SaveVideo(repo)(const VideoSaveRequest(url: 'u', title: 't')),
      isTrue,
    );
    expect(
      await SaveVideo(_Repo(fail: true))(
        const VideoSaveRequest(url: 'u', title: 't'),
      ),
      isFalse,
    );
  });
}
