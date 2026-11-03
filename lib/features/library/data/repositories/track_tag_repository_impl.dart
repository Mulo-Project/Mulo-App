import 'package:shared_preferences/shared_preferences.dart';

import '../../../covers/domain/entities/cover_art.dart';
import '../../domain/entities/file_tags.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_tag_repository.dart';
import '../../../downloads/data/datasources/ffmpeg_tag_writer.dart';
import '../datasources/file_tag_source.dart';
import '../datasources/track_tag_source.dart';

class TrackTagRepositoryImpl implements TrackTagRepository {
  const TrackTagRepositoryImpl(this._source);

  final TrackTagSource _source;

  @override
  Future<TagWriteResult> write(Track track, {CoverArt? cover, int? color}) =>
      _source.write(
        track.uri,
        title: track.title,
        artist: track.artist,
        album: track.album,
        genre: track.genre,
        cover: cover,
        color: color,
      );

  @override
  String? get lastFailure => FfmpegTagWriter.lastError;

  @override
  Future<TagWriteResult> writeLyrics(Track track, String lyrics) =>
      lyrics.trim().isEmpty
      ? Future.value(TagWriteResult.unsupported)
      : _source.write(
          track.uri,
          title: '',
          artist: '',
          album: '',
          genre: '',
          lyrics: lyrics,
          // 가사는 사용자가 직접 저장하므로 쓸 권한이 없으면 동의를 구한다.
          interactive: true,
        );
}

class FileTagRepositoryImpl implements FileTagRepository {
  const FileTagRepositoryImpl(this._source);

  final FileTagSource _source;

  @override
  Future<FileTags?> read(Track track) => _source.read(track.uri);
}

/// 곡 id 목록을 shared_preferences에 기록한다 (태그 이관 · 복원이 키만 다르다).
class _PrefsIdSet {
  const _PrefsIdSet(this._key);

  final String _key;

  Future<Set<String>> load() async =>
      ((await SharedPreferences.getInstance()).getStringList(_key) ?? const [])
          .toSet();

  Future<void> add(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...?prefs.getStringList(_key), ...ids};
    await prefs.setStringList(_key, all.toList());
  }
}

class PrefsTagMigrationStore implements TagMigrationStore {
  static const _ids = _PrefsIdSet('library.tagMigrationDone');

  @override
  Future<Set<String>> loadDone() => _ids.load();

  @override
  Future<void> markDone(Iterable<String> trackIds) => _ids.add(trackIds);
}

class PrefsTagRestoreStore implements TagRestoreStore {
  static const _ids = _PrefsIdSet('library.tagRestoreDone');

  @override
  Future<Set<String>> loadDone() => _ids.load();

  @override
  Future<void> markDone(Iterable<String> trackIds) => _ids.add(trackIds);
}
