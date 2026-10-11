import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';
import 'theme_source.dart';

/// 곡 커버 아트에서 색을 뽑아 팔레트를 만든다. (설정의 "곡 분위기 따라가기"가 켜져 있으면 재생 곡마다 적용)
///
/// 규칙:
/// - 배경 · 표면은 다크/라이트 바탕 그대로. 글로우 그라데이션과 강조 색만 바뀐다.
/// - 강조 색 대비는 [AppPalette.derive]가 배경 대비 7:1 이상으로 보정한다.
/// - 추출 실패 시 [fallback] 팔레트를 쓴다.
///
/// 플레이어 연결 예:
/// ```dart
/// BlocListener<NowPlayingCubit, NowPlayingState>(listener: (context, s) {
///   if (track?.artwork != null) {
///     context.read<ThemeCubit>()
///        .apply(MoodThemeSource(trackId: track!.id, artwork: track.artwork!));
///   }
/// });
/// ```
class MoodThemeSource implements ThemeSource {
  const MoodThemeSource({
    required this.trackId,
    required this.artwork,
    this.fallback = AppPalette.defaultDark,
  });

  final String trackId;
  final ImageProvider artwork;
  final AppPalette fallback;

  @override
  String get id => 'mood:$trackId';

  @override
  Future<AppPalette> resolve(Brightness brightness) async {
    try {
      // Flutter 내장 추출기 (Material Color Utilities). 추가 패키지 불필요.
      // 더 세밀한 추출이 필요하면 palette_generator 등으로 이 부분만 바꾼다.
      final scheme = await ColorScheme.fromImageProvider(
        provider: artwork,
        brightness: brightness,
      );
      return AppPalette.derive(
        primary: scheme.primary,
        accent: scheme.tertiary,
        tertiary: scheme.secondary,
        base: AppPalette.baseFor(brightness),
        minAccentContrast: AppPalette.accentContrastFor(brightness),
      );
    } catch (_) {
      return brightness == Brightness.dark ? fallback : AppPalette.defaultLight;
    }
  }
}

/// 사용자가 곡에 직접 고른 커버 색으로 팔레트를 만든다 (이미지에서 뽑을 필요가 없다).
class MoodColorThemeSource implements ThemeSource {
  const MoodColorThemeSource({required this.trackId, required this.color});

  final String trackId;
  final Color color;

  @override
  String get id => 'mood-color:$trackId:${color.toARGB32()}';

  @override
  AppPalette resolve(Brightness brightness) => AppPalette.derive(
    primary: color,
    accent: color,
    base: AppPalette.baseFor(brightness),
    minAccentContrast: AppPalette.accentContrastFor(brightness),
  );
}
