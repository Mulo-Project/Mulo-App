import 'dart:async';

import 'package:flutter/material.dart' show Brightness, Color;

import '../tokens/app_palette.dart';

/// 팔레트를 만들어 내는 곳. 테마를 바꾸는 방법은 모두 이 인터페이스 하나로 통한다.
///
/// - [ThemePreset]: 설정에서 고르는 색 프리셋 8개 (기본 = 바이올렛 · 라임)
/// - [CustomThemeSource]: 사용자가 고른 주 색 · 강조 색 (저장소에 보관)
/// - [MoodThemeSource]: 재생 중인 곡의 커버 아트에서 색 추출
abstract interface class ThemeSource {
  /// 같은 소스인지 비교하는 키. 컨트롤러가 중복 적용을 거른다.
  String get id;

  /// [brightness](다크 · 라이트)에 맞는 팔레트.
  FutureOr<AppPalette> resolve(Brightness brightness);
}

/// 사용자 지정 테마 설정값. 저장 · 복원 단위.
class CustomThemeSpec {
  const CustomThemeSpec({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  Map<String, int> toJson() => {
    'primary': primary.toARGB32(),
    'accent': accent.toARGB32(),
  };

  factory CustomThemeSpec.fromJson(Map<String, Object?> json) =>
      CustomThemeSpec(
        primary: Color(json['primary']! as int),
        accent: Color(json['accent']! as int),
      );
}

/// 사용자 지정 테마 저장소. 구현(SharedPreferences, 서버 동기화 등)은 나중에 붙인다.
abstract interface class CustomThemeStore {
  Future<CustomThemeSpec?> load();
  Future<void> save(CustomThemeSpec spec);
}

/// 저장소가 붙기 전까지 쓰는 메모리 구현.
class InMemoryCustomThemeStore implements CustomThemeStore {
  CustomThemeSpec? _spec;

  @override
  Future<CustomThemeSpec?> load() async => _spec;

  @override
  Future<void> save(CustomThemeSpec spec) async => _spec = spec;
}

/// 사용자가 고른 두 색으로 팔레트를 만든다.
/// 배경은 검정 유지, 강조 색 대비는 [AppPalette.derive]가 보정한다.
class CustomThemeSource implements ThemeSource {
  const CustomThemeSource(this.spec);

  final CustomThemeSpec spec;

  @override
  String get id =>
      'custom:${spec.primary.toARGB32()}:${spec.accent.toARGB32()}';

  @override
  AppPalette resolve(Brightness brightness) => AppPalette.derive(
    primary: spec.primary,
    accent: spec.accent,
    base: AppPalette.baseFor(brightness),
    minAccentContrast: AppPalette.accentContrastFor(brightness),
  );
}
