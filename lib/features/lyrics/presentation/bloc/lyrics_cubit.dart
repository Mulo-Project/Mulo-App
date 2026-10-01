import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/usecases/lyrics_usecases.dart';

export '../../domain/entities/lyrics.dart';

/// 지금 보고 있는 곡([trackId])의 가사. [lyrics]가 null이고 [loading]이 아니면 가사 없음.
class LyricsState extends Equatable {
  const LyricsState({this.trackId, this.lyrics, this.loading = false});

  final String? trackId;
  final Lyrics? lyrics;
  final bool loading;

  @override
  List<Object?> get props => [trackId, lyrics, loading];
}

/// 플레이어가 보여 줄 가사를 불러오고, 곡 메뉴의 가사 설정을 저장한다.
class LyricsCubit extends Cubit<LyricsState> {
  LyricsCubit({
    required this._load,
    required this._save,
    required this._clear,
    required this._pickFile,
  }) : super(const LyricsState());

  final LoadLyrics _load;
  final SaveLyrics _save;
  final ClearLyrics _clear;
  final PickLyricsFile _pickFile;

  /// [track]의 가사를 보여 줄 대상으로 불러온다. 이미 그 곡이면 다시 읽지 않는다.
  Future<void> show(Track track) async {
    if (state.trackId == track.id) return;
    emit(LyricsState(trackId: track.id, loading: true));
    final lyrics = await _load(LoadLyricsParams(track.id, track.uri));
    if (isClosed || state.trackId != track.id) return;
    emit(LyricsState(trackId: track.id, lyrics: lyrics));
  }

  /// 저장된 가사(없으면 음원 옆 `.lrc`)의 원문. 편집 화면의 처음 글.
  Future<String> currentText(Track track) async =>
      (await _load(LoadLyricsParams(track.id, track.uri)))?.raw ?? '';

  /// 가사 파일을 골라 글을 읽어 온다. 취소하면 null.
  Future<String?> pickFile() => _pickFile(const NoParams());

  /// [text]를 [trackId] 곡의 가사로 저장한다 (비면 지움).
  Future<void> save(String trackId, String text) async {
    final lyrics = await _save(SaveLyricsParams(trackId, text));
    if (!isClosed && state.trackId == trackId) {
      emit(LyricsState(trackId: trackId, lyrics: lyrics));
    }
  }

  Future<void> clear(String trackId) async {
    await _clear(trackId);
    if (!isClosed && state.trackId == trackId) {
      emit(LyricsState(trackId: trackId));
    }
  }
}
