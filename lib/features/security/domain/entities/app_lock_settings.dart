import 'package:equatable/equatable.dart';

/// 앱 잠금 설정. PIN 자체는 담지 않는다 (저장소 안에서만 다룬다).
class AppLockSettings extends Equatable {
  const AppLockSettings({this.enabled = false, this.biometricEnabled = false});

  final bool enabled;
  final bool biometricEnabled;

  /// PIN 길이 범위 (자릿수).
  static const pinMinLength = 4;
  static const pinMaxLength = 6;

  static bool isValidPin(String pin) =>
      pin.length >= pinMinLength &&
      pin.length <= pinMaxLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  @override
  List<Object?> get props => [enabled, biometricEnabled];
}
