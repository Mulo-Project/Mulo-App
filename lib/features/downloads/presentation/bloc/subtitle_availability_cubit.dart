import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../search/domain/entities/media_info.dart';
import '../../../search/domain/usecases/search_usecases.dart';

enum SubtitleStatus { checking, found, none, unknown }

/// 받기 전에 본 영상에 자막이 있는지 · 어떤 언어인지.
class SubtitleAvailability extends Equatable {
  const SubtitleAvailability(
    this.status, [
    this.languages = const [],
    this.automatic = const {},
  ]);

  final SubtitleStatus status;
  final List<String> languages;

  /// [languages] 가운데 자동 생성 자막인 것.
  final Set<String> automatic;

  @override
  List<Object?> get props => [status, languages, automatic];
}

/// 받기 페이지가 열릴 때 곡 정보에서 자막 언어를 읽는다 (이미 알면 읽지 않는다).
/// 읽지 못하면 [SubtitleStatus.unknown]으로 두고, 받기는 그대로 할 수 있다.
class SubtitleAvailabilityCubit extends Cubit<SubtitleAvailability> {
  SubtitleAvailabilityCubit(this._fetchInfo)
    : super(const SubtitleAvailability(SubtitleStatus.checking));

  final FetchMediaInfo _fetchInfo;

  Future<void> load(
    String url, {
    List<String>? known,
    List<String> knownAutomatic = const [],
  }) async {
    if (known != null && known.isNotEmpty) {
      emit(
        SubtitleAvailability(SubtitleStatus.found, known, {...knownAutomatic}),
      );
      return;
    }
    try {
      final info = await _fetchInfo(url);
      if (isClosed) return;
      final hit = info is VideoInfo ? info.hit : null;
      final langs = hit?.subtitleLangs ?? const <String>[];
      emit(
        langs.isEmpty
            ? const SubtitleAvailability(SubtitleStatus.none)
            : SubtitleAvailability(SubtitleStatus.found, langs, {
                ...?hit?.autoSubtitleLangs,
              }),
      );
    } on Object {
      if (!isClosed) {
        emit(const SubtitleAvailability(SubtitleStatus.unknown));
      }
    }
  }
}
