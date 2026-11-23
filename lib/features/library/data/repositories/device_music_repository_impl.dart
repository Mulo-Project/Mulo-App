import '../../domain/entities/import_result.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/device_music_data_sources.dart';

/// 기기 음악 찾기: Android는 MediaStore, 데스크톱은 폴더 스캔 (DI에서 고른다).
class DeviceMusicRepositoryImpl implements DeviceMusicRepository {
  const DeviceMusicRepositoryImpl(this._source);

  final DeviceMusicDataSource _source;

  @override
  Future<ScanResult> scan(List<String> folders) => _source.scan(folders);
}
