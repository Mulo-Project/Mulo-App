import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/theme_source/theme_presets.dart';
import '../../../../core/design/theme_source/theme_source.dart';
import '../../../../core/design/tokens/app_palette.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/theme_settings.dart';
import '../../domain/usecases/theme_usecases.dart';

class ThemeState extends Equatable {
  const ThemeState({
    required this.sourceId,
    required this.dark,
    required this.light,
    this.preset = ThemePreset.initial,
    this.mode = AppThemeMode.initial,
    this.previewing = false,
  });

  factory ThemeState.initial() {
    const p = ThemePreset.initial;
    return ThemeState(
      sourceId: p.id,
      dark: p.paletteFor(Brightness.dark),
      light: p.paletteFor(Brightness.light),
    );
  }

  /// 지금 화면에 적용된 소스 (프리셋 · 곡 분위기 등).
  final String sourceId;

  /// 같은 소스의 다크 · 라이트 팔레트. 어느 쪽을 쓸지는 [mode]가 정한다.
  final AppPalette dark;
  final AppPalette light;

  /// 사용자가 설정에서 고른 프리셋. 곡 분위기 테마가 적용 중이어도 유지된다.
  final ThemePreset preset;
  final AppThemeMode mode;

  /// 테마 미리보기 중 (저장 전). 하단에 적용 · 취소 바가 뜬다.
  final bool previewing;

  ThemeMode get materialMode =>
      mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

  AppPalette paletteFor(Brightness b) => b == Brightness.dark ? dark : light;

  ThemeState copyWith({
    String? sourceId,
    AppPalette? dark,
    AppPalette? light,
    ThemePreset? preset,
    AppThemeMode? mode,
    bool? previewing,
  }) => ThemeState(
    sourceId: sourceId ?? this.sourceId,
    dark: dark ?? this.dark,
    light: light ?? this.light,
    preset: preset ?? this.preset,
    mode: mode ?? this.mode,
    previewing: previewing ?? this.previewing,
  );

  @override
  List<Object?> get props => [sourceId, dark, light, preset, mode, previewing];
}

/// 앱 테마 (프리셋 · 화면 모드 · 임시 소스). 바뀌면 MaterialApp이
/// [AppThemeTokens.lerp]로 부드럽게 넘긴다.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required LoadThemeSettings loadSettings,
    required this._savePreset,
    required this._saveMode,
  }) : _load = loadSettings,
       super(ThemeState.initial());

  final LoadThemeSettings _load;
  final SaveThemePreset _savePreset;
  final SaveThemeMode _saveMode;
  int _request = 0;
  ThemePreset? _savedPreset;
  AppThemeMode? _savedMode;
  bool _touched = false;

  /// 저장된 설정을 불러온다. 앱 시작 때 한 번.
  Future<void> load() async {
    final saved = await _load(const NoParams());
    // 불러오는 사이에 사용자가 이미 바꿨으면 덮어쓰지 않는다.
    if (_touched || isClosed) return;
    emit(state.copyWith(mode: saved.mode));
    final preset = ThemePreset.fromId(saved.presetId);
    if (preset != null) await _applyPreset(preset);
  }

  /// 설정에서 프리셋을 고른다. 저장해서 다음 실행에도 유지한다.
  Future<void> selectPreset(ThemePreset preset) async {
    _touched = true;
    await _applyPreset(preset);
    await _savePreset(preset.id);
  }

  /// 화면 모드(다크 · 라이트)를 고른다. 저장한다.
  Future<void> selectMode(AppThemeMode mode) async {
    _touched = true;
    emit(state.copyWith(mode: mode));
    await _saveMode(mode);
  }

  /// 미리보기를 시작한다. 이후 [previewPreset] · [previewMode]는 저장하지 않고,
  /// [applyPreview]로 저장하거나 [cancelPreview]로 시작 전 테마로 돌아간다.
  void beginPreview() {
    if (state.previewing) return;
    _savedPreset = state.preset;
    _savedMode = state.mode;
    emit(state.copyWith(previewing: true));
  }

  Future<void> previewPreset(ThemePreset preset) => _applyPreset(preset);

  void previewMode(AppThemeMode mode) => emit(state.copyWith(mode: mode));

  /// 미리보던 테마를 저장하고 미리보기를 끝낸다.
  Future<void> applyPreview() async {
    if (!state.previewing) return;
    _touched = true;
    emit(state.copyWith(previewing: false));
    await _savePreset(state.preset.id);
    await _saveMode(state.mode);
  }

  /// 미리보기를 끝내고 시작 전 테마로 돌아간다.
  Future<void> cancelPreview() async {
    if (!state.previewing) return;
    final mode = _savedMode ?? state.mode;
    emit(state.copyWith(previewing: false, mode: mode));
    await _applyPreset(_savedPreset ?? state.preset);
  }

  Future<void> _applyPreset(ThemePreset preset) async {
    await apply(preset);
    if (!isClosed) emit(state.copyWith(preset: preset));
  }

  /// 임의의 소스 적용 (곡 분위기 등). 저장하지 않는다.
  Future<void> apply(ThemeSource source) async {
    if (source.id == state.sourceId) return;
    final request = ++_request;
    final dark = await source.resolve(Brightness.dark);
    final light = await source.resolve(Brightness.light);
    // 곡이 빠르게 바뀌면 늦게 끝난 이전 추출 결과는 버린다.
    if (request != _request || isClosed) return;
    emit(state.copyWith(sourceId: source.id, dark: dark, light: light));
  }

  /// 고른 프리셋으로 돌아간다 (예: 곡 분위기 따라가기를 끌 때).
  Future<void> reset() => apply(state.preset);
}
