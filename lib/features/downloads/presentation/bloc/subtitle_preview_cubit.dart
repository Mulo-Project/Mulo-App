import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../search/domain/entities/subtitle_track.dart';
import '../../../search/domain/usecases/search_usecases.dart';

enum SubtitlePreviewStatus { idle, loading, loaded, failed }

class SubtitlePreview extends Equatable {
  const SubtitlePreview(this.status, [this.track]);

  final SubtitlePreviewStatus status;

  /// 불러온 자막. [SubtitlePreviewStatus.loaded]일 때만 있다.
  final SubtitleTrack? track;

  @override
  List<Object?> get props => [status, track];
}

/// 받기 전에 가져올 자막의 앞부분을 미리 읽어 본다 (받지 않고 자막만 읽는다).
class SubtitlePreviewCubit extends Cubit<SubtitlePreview> {
  SubtitlePreviewCubit(this._fetch)
    : super(const SubtitlePreview(SubtitlePreviewStatus.idle));

  final FetchSubtitles _fetch;

  /// [language]가 null이면 받을 때와 같이 자동으로 고른다.
  Future<void> load(
    String url, {
    String? language,
    bool skipSounds = true,
  }) async {
    emit(const SubtitlePreview(SubtitlePreviewStatus.loading));
    try {
      final track = await _fetch(
        FetchSubtitlesParams(url, language == null ? null : [language]),
      );
      if (isClosed) return;
      final shown = skipSounds ? track?.withoutSoundCues() : track;
      emit(
        shown == null || shown.cues.isEmpty
            ? const SubtitlePreview(SubtitlePreviewStatus.failed)
            : SubtitlePreview(SubtitlePreviewStatus.loaded, shown),
      );
    } on Object {
      if (!isClosed) {
        emit(const SubtitlePreview(SubtitlePreviewStatus.failed));
      }
    }
  }

  /// 이미 가지고 있는 자막을 그대로 보여 준다 (고쳐 둔 글을 다시 열 때).
  void show(SubtitleTrack track) =>
      emit(SubtitlePreview(SubtitlePreviewStatus.loaded, track));

  /// 고른 언어가 바뀌어 지금 미리보기가 맞지 않을 때 비운다.
  void clear() => emit(const SubtitlePreview(SubtitlePreviewStatus.idle));
}
