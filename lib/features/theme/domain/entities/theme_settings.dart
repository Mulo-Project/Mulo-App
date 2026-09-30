import 'package:equatable/equatable.dart';

/// 화면 모드. 기기 설정을 따르지 않고 앱에서 고른다 (기본 다크, D-018).
enum AppThemeMode {
  dark,
  light;

  static const AppThemeMode initial = dark;
}

/// 저장된 테마 설정. 프리셋은 id 문자열로만 다룬다 (색은 presentation이 안다).
class ThemeSettings extends Equatable {
  const ThemeSettings({this.presetId, this.mode = AppThemeMode.initial});

  /// 저장된 프리셋 id. 없으면 기본 프리셋.
  final String? presetId;
  final AppThemeMode mode;

  @override
  List<Object?> get props => [presetId, mode];
}
