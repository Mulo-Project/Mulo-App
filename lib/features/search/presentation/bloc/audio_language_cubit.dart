import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart' show debugPrint;

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
  AudioLanguageCubit(this._fetch, {Locale Function()? systemLocale})
    : _systemLocale = systemLocale ?? (() => PlatformDispatcher.instance.locale),
      super(const AudioLanguageState());

  final FetchAudioLanguages _fetch;
  final Locale Function() _systemLocale;

  /// 고르지 않았을 때의 기본 언어: 기기(시스템) 언어 · 국가와 맞는 트랙. 영상의 기본 음성이 이미 맞거나
  /// 맞는 트랙이 없으면 null (기본 음성). 국가까지 맞는 트랙(`en-US`)을 먼저, 없으면 언어만 맞는 트랙.
  String? _systemDefault(List<AudioLanguage> languages) {
    if (languages.length < 2) return null;
    final locale = _systemLocale();
    final lang = locale.languageCode.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    AudioLanguage? byLanguage;
    for (final l in languages) {
      final parts = l.id.split(RegExp('[-_]'));
      if (parts.first.toLowerCase() != lang) continue;
      if (country != null && parts.length > 1 && parts[1].toUpperCase() == country) {
        return l.isDefault ? null : l.id;
      }
      byLanguage ??= l;
    }
    if (byLanguage == null || byLanguage.isDefault) return null;
    return byLanguage.id;
  }

  Future<void>? _loading;

  /// 언어 목록을 다 읽을 때까지 (최대 [timeout]) 기다린 뒤 고른(기본) 언어를 돌려준다.
  /// 목록을 읽기 전에 미리 듣기를 누르면 시스템 언어 기본값이 빠지므로, 시작 전에 이걸 쓴다.
  Future<String?> selectedWhenReady({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final loading = _loading;
    if (loading != null) {
      try {
        await loading.timeout(timeout);
      } on Object {
        // 못 기다리면 지금 값으로 간다.
      }
    }
    return state.selected;
  }

  Future<void> load(String url, {String? selected}) {
    final f = _load(url, selected);
    _loading = f;
    return f;
  }

  Future<void> _load(String url, String? selected) async {
    final languages = await _fetch(url);
    if (isClosed) return;
    final chosen = languages.any((l) => l.id == selected)
        ? selected
        : _systemDefault(languages);
    debugPrint(
      '[lang] 오디오 언어 ${languages.map((l) => l.id).join(',')} '
      '시스템 ${_systemLocale().toLanguageTag()} → ${chosen ?? '기본 음성'}',
    );
    emit(AudioLanguageState(languages: languages, selected: chosen));
  }

  void select(String id) {
    if (!state.languages.any((l) => l.id == id)) return;
    emit(AudioLanguageState(languages: state.languages, selected: id));
  }
}
