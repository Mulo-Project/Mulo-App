import '../../domain/entities/track.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/track_file_data_source.dart';

class TrackFileRepositoryImpl implements TrackFileRepository {
  const TrackFileRepositoryImpl(this._source);

  final TrackFileDataSource _source;

  @override
  Future<bool> deleteFile(Track track) => _source.delete(track.uri);
}
