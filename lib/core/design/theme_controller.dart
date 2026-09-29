import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_source/theme_source.dart';
import 'tokens/app_palette.dart';

@immutable
class ThemeState {
  const ThemeState({required this.sourceId, required this.palette});

  final String sourceId;
  final AppPalette palette;
}

/// 현재 테마를 가진다. 소스를 [apply]하면 팔레트가 바뀌고,
/// MaterialApp의 테마 애니메이션이 [AppThemeTokens.lerp]로 부드럽게 넘긴다.
class ThemeController extends Notifier<ThemeState> {
  int _request = 0;

  @override
  ThemeState build() =>
      const ThemeState(sourceId: 'default', palette: AppPalette.defaultDark);

  Future<void> apply(ThemeSource source) async {
    if (source.id == state.sourceId) return;
    final request = ++_request;
    final palette = await source.resolve();
    // 곡이 빠르게 바뀌면 늦게 끝난 이전 추출 결과는 버린다.
    if (request != _request) return;
    state = ThemeState(sourceId: source.id, palette: palette);
  }

  Future<void> reset() => apply(const DefaultThemeSource());
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
