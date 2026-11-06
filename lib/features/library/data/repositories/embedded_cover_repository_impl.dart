import '../../domain/entities/track.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/embedded_cover_source.dart';

class EmbeddedCoverRepositoryImpl implements EmbeddedCoverRepository {
  const EmbeddedCoverRepositoryImpl(this._source);

  final EmbeddedCoverSource _source;

  @override
  Future<String?> extract(Track track) => _source.extract(track.uri);

  @override
  Future<void> discard(String path) => _source.discard(path);

  @override
  String takeSummary() => EmbeddedCoverSource.takeSummary();
}
