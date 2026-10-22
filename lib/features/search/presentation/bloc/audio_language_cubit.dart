import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/audio_language.dart';
import '../../domain/usecases/search_usecases.dart';

class AudioLanguageState extends Equatable {
  const AudioLanguageState({this.languages = const [], this.selected});

  /// 곡에 들어 있는 오디오 언어들. 고를 수 있는 게 없으면(트랙 하나 · 못 읽음) 비어 있다.
  final List<AudioLanguage> languages;

  /// 고른 언어 코드. null이면 영상의 기본 음성.
  final String? selected;

  bool get choosable => languages.length > 1;

  /// 지금 듣거나 받게 되는 언어 (고르지 않았으면 기본 음성).
  AudioLanguage? get current {
    for (final l in languages) {
      if (selected == null ? l.isDefault : l.id == selected) return l;
    }
    return languages.firstOrNull;
  }

  @override
  List<Object?> get props => [languages, selected];
}

/// 곡의 오디오 언어 목록을 읽고, 미리 듣기 · 받기에 쓸 언어를 고른다.
/// 읽지 못하면 비어 있는 채로 두고, 그러면 기본 음성으로 듣고 받는다.
class AudioLanguageCubit extends Cubit<AudioLanguageState> {
  AudioLanguageCubit(this._fetch) : super(const AudioLanguageState());

  final FetchAudioLanguages _fetch;

  Future<void> load(String url, {String? selected}) async {
    final languages = await _fetch(url);
    if (isClosed) return;
    emit(
      AudioLanguageState(
        languages: languages,
        selected: languages.any((l) => l.id == selected) ? selected : null,
      ),
    );
  }

  void select(String id) {
    if (!state.languages.any((l) => l.id == id)) return;
    emit(AudioLanguageState(languages: state.languages, selected: id));
  }
}
