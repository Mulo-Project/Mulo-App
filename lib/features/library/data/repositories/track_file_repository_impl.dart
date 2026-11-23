import '../../domain/entities/track.dart';
import '../../domain/entities/track_file_info.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/track_file_data_source.dart';

class TrackFileRepositoryImpl implements TrackFileRepository {
  const TrackFileRepositoryImpl(this._source);

  final TrackFileDataSource _source;

  @override
  Future<bool> deleteFile(Track track) => _source.delete(track.uri);

  @override
  Future<Set<String>> deleteFiles(List<Track> tracks) async {
    final deleted = await _source.deleteAll([for (final t in tracks) t.uri]);
    return {
      for (final t in tracks)
        if (deleted.contains(t.uri)) t.id,
    };
  }

  @override
  Future<TrackFileInfo?> fileInfo(Track track) => _source.info(track.uri);
}
