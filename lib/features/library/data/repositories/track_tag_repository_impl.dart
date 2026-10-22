import 'package:shared_preferences/shared_preferences.dart';

import '../../../covers/domain/entities/cover_art.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_tag_repository.dart';
import '../datasources/track_tag_source.dart';

class TrackTagRepositoryImpl implements TrackTagRepository {
  const TrackTagRepositoryImpl(this._source);

  final TrackTagSource _source;

  @override
  Future<bool> write(Track track, {CoverArt? cover, int? color}) =>
      _source.write(
        track.uri,
        title: track.title,
        artist: track.artist,
        album: track.album,
        genre: track.genre,
        cover: cover,
        color: color,
      );
}

class PrefsTagMigrationStore implements TagMigrationStore {
  static const _key = 'library.tagMigrationDone';

  @override
  Future<Set<String>> loadDone() async =>
      ((await SharedPreferences.getInstance()).getStringList(_key) ?? const [])
          .toSet();

  @override
  Future<void> markDone(Iterable<String> trackIds) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...?prefs.getStringList(_key), ...trackIds};
    await prefs.setStringList(_key, all.toList());
  }
}
