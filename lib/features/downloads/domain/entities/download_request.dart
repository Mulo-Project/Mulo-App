import 'package:equatable/equatable.dart';

import '../../../covers/domain/entities/cover_art.dart';
import 'download_options.dart';

/// 받기 팝업에서 사용자가 정한 것: 곡 정보 · 장르 · 받은 뒤 넣을 재생목록.
class DownloadRequest extends Equatable {
  const DownloadRequest({
    required this.title,
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.playlistIds = const {},
    this.quality,
    this.format,
    this.savePath = '',
    this.duration,
    this.color,
    this.thumbnailUrl,
    this.cover,
    this.url = '',
    this.importLyrics = false,
    this.lyricsLanguage,
    this.lyricsSkipSounds = true,
    this.lyricsText,
    this.audioLanguage,
  });

  final String title;

  /// 모르면 빈 문자열.
  final String artist;

  /// 앨범. 모르면 빈 문자열.
  final String album;
  final String genre;
  final Set<String> playlistIds;

  /// 이 곡의 음질 · 저장 형식. null이면 받을 때 설정의 기본 음질 · 포맷을 읽어 쓴다.
  final Quality? quality;
  final AudioFormat? format;

  /// 받은 곡을 저장할 폴더. 비어 있으면 기본 저장 위치.
  final String savePath;

  /// 곡 길이. 모르면 null (대기열 타일에 그대로 이어서 보여 준다).
  final Duration? duration;

  /// 받은 곡의 커버 색(ARGB). 비어 있으면 자동 색.
  final int? color;

  /// 영상 대표 이미지 주소(웹). 받은 곡의 기본 커버로 쓴다. 없으면 null.
  final String? thumbnailUrl;

  /// 받은 곡에 붙일 커버(이미지 · 확대 · 위치). 기본은 [thumbnailUrl]의 웹 이미지, 없으면 null.
  final CoverArt? cover;

  /// 받을 곡의 원본 주소 (유튜브 등). 비어 있으면 받을 수 없다.
  final String url;

  /// 받은 뒤 영상 자막을 가사로 가져온다 (자막이 없거나 못 읽으면 건너뛴다).
  final bool importLyrics;

  /// 가져올 자막 언어 코드. null이면 한국어 → 영어 → 첫 언어 순으로 고른다.
  final String? lyricsLanguage;

  /// 가져올 때 효과음 줄(`[음악]` 등)을 뺀다.
  final bool lyricsSkipSounds;

  /// 받기 전에 글을 고친 가사(.lrc 글). 있으면 자막을 다시 읽지 않고 이것을 저장한다.
  final String? lyricsText;

  /// 받을 오디오 언어 코드 (다국어 음원에서 고른 것). null이면 영상의 기본 음성.
  final String? audioLanguage;

  /// 문자열 앞뒤 공백을 지운 사본.
  DownloadRequest normalized() => DownloadRequest(
    title: title.trim(),
    artist: artist.trim(),
    album: album.trim(),
    genre: genre.trim(),
    playlistIds: playlistIds,
    quality: quality,
    format: format,
    savePath: savePath.trim(),
    duration: duration,
    color: color,
    thumbnailUrl: thumbnailUrl,
    cover: cover,
    url: url.trim(),
    importLyrics: importLyrics,
    lyricsLanguage: lyricsLanguage,
    lyricsSkipSounds: lyricsSkipSounds,
    lyricsText: lyricsText,
    audioLanguage: audioLanguage,
  );

  @override
  List<Object?> get props => [
    title,
    artist,
    album,
    genre,
    playlistIds,
    quality,
    format,
    savePath,
    duration,
    color,
    thumbnailUrl,
    cover,
    url,
    importLyrics,
    lyricsLanguage,
    lyricsSkipSounds,
    lyricsText,
    audioLanguage,
  ];
}
