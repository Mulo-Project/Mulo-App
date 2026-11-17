import '../../../engine/data/native_yt_dlp.dart';
import '../../domain/repositories/video_save_repository.dart';

/// 네이티브 yt-dlp 엔진이 들어 있는 빌드인지로 영상 저장 지원 여부를 답한다.
class NativeVideoSaveRepository implements VideoSaveRepository {
  NativeVideoSaveRepository(this._ytDlp);

  final NativeYtDlp _ytDlp;

  @override
  Future<bool> isAvailable() => _ytDlp.isAvailable();
}
