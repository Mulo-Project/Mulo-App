import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';
import 'theme_source.dart';

/// 곡 커버 아트에서 색을 뽑아 팔레트를 만든다. (실험용 — 아직 플레이어에 연결 안 됨)
///
/// 규칙:
/// - 배경 · 표면은 검정 그대로. 글로우 그라데이션과 강조 색만 바뀐다.
/// - 강조 색 대비는 [AppPalette.derive]가 배경 대비 7:1 이상으로 보정한다.
/// - 추출 실패 시 [fallback] 팔레트를 쓴다.
///
/// 플레이어 연결 예:
/// ```dart
/// ref.listen(currentTrackProvider, (_, track) {
///   if (track?.artwork != null) {
///     ref.read(themeControllerProvider.notifier)
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
  Future<AppPalette> resolve() async {
    try {
      // Flutter 내장 추출기 (Material Color Utilities). 추가 패키지 불필요.
      // 더 세밀한 추출이 필요하면 palette_generator 등으로 이 부분만 바꾼다.
      final scheme = await ColorScheme.fromImageProvider(
        provider: artwork,
        brightness: Brightness.dark,
      );
      return AppPalette.derive(
        primary: scheme.primary,
        accent: scheme.tertiary,
        tertiary: scheme.secondary,
        base: fallback,
      );
    } catch (_) {
      return fallback;
    }
  }
}
