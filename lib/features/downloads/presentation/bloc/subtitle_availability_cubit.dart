import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../search/domain/entities/media_info.dart';
import '../../../search/domain/usecases/search_usecases.dart';

enum SubtitleStatus { checking, found, none, unknown }

/// 받기 전에 본 영상에 자막이 있는지 · 어떤 언어인지.
class SubtitleAvailability extends Equatable {
  const SubtitleAvailability(this.status, [this.languages = const []]);

  final SubtitleStatus status;
  final List<String> languages;

  @override
  List<Object?> get props => [status, languages];
}

/// 받기 페이지가 열릴 때 곡 정보에서 자막 언어를 읽는다 (이미 알면 읽지 않는다).
/// 읽지 못하면 [SubtitleStatus.unknown]으로 두고, 받기는 그대로 할 수 있다.
class SubtitleAvailabilityCubit extends Cubit<SubtitleAvailability> {
  SubtitleAvailabilityCubit(this._fetchInfo)
    : super(const SubtitleAvailability(SubtitleStatus.checking));

  final FetchMediaInfo _fetchInfo;

  Future<void> load(String url, {List<String>? known}) async {
    if (known != null && known.isNotEmpty) {
      emit(SubtitleAvailability(SubtitleStatus.found, known));
      return;
    }
    try {
      final info = await _fetchInfo(url);
      if (isClosed) return;
      final langs = info is VideoInfo ? info.hit.subtitleLangs : <String>[];
      emit(
        langs.isEmpty
            ? const SubtitleAvailability(SubtitleStatus.none)
            : SubtitleAvailability(SubtitleStatus.found, langs),
      );
    } on Object {
      if (!isClosed) {
        emit(const SubtitleAvailability(SubtitleStatus.unknown));
      }
    }
  }
}
