import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/video_quality.dart';
import '../../domain/repositories/video_quality_repository.dart';

/// shared_preferences에 화질 이름을 저장한다. 모르는 값이면 기본 화질.
class PrefsVideoQualityRepository implements VideoQualityRepository {
  static const _key = 'search.videoQuality';

  @override
  Future<VideoQuality> load() async {
    final name = (await SharedPreferences.getInstance()).getString(_key);
    return VideoQuality.values.firstWhere(
      (q) => q.name == name,
      orElse: () => VideoQuality.standard,
    );
  }

  @override
  Future<void> save(VideoQuality value) async {
    await (await SharedPreferences.getInstance()).setString(_key, value.name);
  }
}
