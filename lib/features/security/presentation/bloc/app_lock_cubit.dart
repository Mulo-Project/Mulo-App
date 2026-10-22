import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/app_lock_usecases.dart';

class AppLockState extends Equatable {
  const AppLockState({
    this.loaded = false,
    this.enabled = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.locked = false,
    this.failedAttempts = 0,
    this.cooldownUntil,
  });

  /// 저장된 설정을 다 불러왔는지. 그 전에는 잠겨 있다고 보고 내용을 가린다.
  final bool loaded;
  final bool enabled;
  final bool biometricEnabled;

  /// 기기에 생체 인증이 등록돼 있는지.
  final bool biometricAvailable;

  /// 지금 잠금 화면이 떠 있어야 하는지.
  final bool locked;

  /// 이어서 틀린 횟수. 맞추면 0으로 돌아간다.
  final int failedAttempts;

  /// 이 시각까지는 PIN 입력을 받지 않는다 (연속 실패 뒤 잠시 멈춤).
  final DateTime? cooldownUntil;

  AppLockState copyWith({
    bool? loaded,
    bool? enabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
    bool? locked,
    int? failedAttempts,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
  }) => AppLockState(
    loaded: loaded ?? this.loaded,
    enabled: enabled ?? this.enabled,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    locked: locked ?? this.locked,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    cooldownUntil: clearCooldown ? null : cooldownUntil ?? this.cooldownUntil,
  );

  @override
  List<Object?> get props => [
    loaded,
    enabled,
    biometricEnabled,
    biometricAvailable,
    locked,
    failedAttempts,
    cooldownUntil,
  ];
}

/// 앱 잠금 (PIN · 생체 인증). 앱을 열 때 켜져 있으면 잠금 화면을 띄운다.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit({
    required this._load,
    required this._enable,
    required this._disable,
    required this._turnOff,
    required this._verify,
    required this._setBiometric,
    required this._isBiometricAvailable,
    required this._authenticateBiometric,
    this._now = DateTime.now,
  }) : super(const AppLockState());

  /// 이만큼 이어서 틀리면 [cooldown] 동안 입력을 멈춘다.
  static const maxAttempts = 5;
  static const cooldown = Duration(seconds: 30);

  final LoadAppLock _load;
  final EnableAppLock _enable;
  final DisableAppLock _disable;
  final TurnOffAppLock _turnOff;
  final VerifyPin _verify;
  final SetBiometric _setBiometric;
  final IsBiometricAvailable _isBiometricAvailable;
  final AuthenticateBiometric _authenticateBiometric;
  final DateTime Function() _now;

  /// 앱이 화면에서 사라진 시각 (돌아올 때 얼마나 비웠는지 본다).
  DateTime? _leftAt;

  /// 저장된 생체 인증 사용 여부 (기기에서 쓸 수 없는 순간에도 설정은 잃지 않는다).
  bool _savedBiometric = false;

  /// 앱 시작 때 한 번. 켜져 있으면 잠근 채로 시작한다.
  Future<void> load() async {
    final saved = await _load(const NoParams());
    final available = await _isBiometricAvailable(const NoParams());
    if (isClosed) return;
    _savedBiometric = saved.biometricEnabled;
    emit(
      state.copyWith(
        loaded: true,
        enabled: saved.enabled,
        biometricEnabled: saved.biometricEnabled && available,
        biometricAvailable: available,
        locked: saved.enabled,
      ),
    );
  }

  /// 생체 인증을 쓸 수 있는지 다시 본다. 앱 시작 직후엔 화면이 엔진에 붙기 전이라 안드로이드가
  /// "없음"으로 답할 수 있어서, 시작 때 한 번만 보면 지문이 꺼진 채로 굳는다. 앞으로 돌아올 때 · 잠금 화면에서 부른다.
  Future<void> refreshBiometric() async {
    if (!state.loaded) return;
    final available = await _isBiometricAvailable(const NoParams());
    if (isClosed) return;
    emit(
      state.copyWith(
        biometricAvailable: available,
        biometricEnabled: _savedBiometric && available,
      ),
    );
  }

  /// 이 시간 넘게 앱을 벗어났다 돌아오면 다시 잠근다. 짧은 앱 전환 ·
  /// 파일 선택창 · 권한 창을 다녀올 때마다 잠기지 않게 하는 여유다.
  static const relockAfter = Duration(seconds: 10);

  /// 앱이 백그라운드로 갔다.
  void appLeft() => _leftAt ??= _now();

  /// 앱이 다시 앞으로 왔다 (알림을 눌러 돌아온 경우 포함).
  /// 잠금이 켜져 있고 [relockAfter] 넘게 비웠으면 잠금 화면을 먼저 띄운다.
  void appReturned() {
    final left = _leftAt;
    _leftAt = null;
    if (left == null || !state.loaded || !state.enabled || state.locked) return;
    if (_now().difference(left) >= relockAfter) {
      emit(state.copyWith(locked: true));
    }
  }

  bool get inCooldown {
    final until = state.cooldownUntil;
    return until != null && _now().isBefore(until);
  }

  /// PIN으로 잠금을 푼다. 맞으면 true.
  Future<bool> unlock(String pin) async {
    if (inCooldown) return false;
    if (await _verify(pin)) {
      emit(
        state.copyWith(locked: false, failedAttempts: 0, clearCooldown: true),
      );
      return true;
    }
    final failed = state.failedAttempts + 1;
    final reached = failed >= maxAttempts;
    emit(
      state.copyWith(
        failedAttempts: reached ? 0 : failed,
        cooldownUntil: reached ? _now().add(cooldown) : null,
      ),
    );
    return false;
  }

  /// 생체 인증으로 잠금을 푼다. [reason]은 인증 창 안내 문구.
  Future<bool> unlockWithBiometric(String reason) async {
    if (!state.biometricEnabled) return false;
    if (!await _authenticateBiometric(reason)) return false;
    emit(state.copyWith(locked: false, failedAttempts: 0, clearCooldown: true));
    return true;
  }

  /// 설정에서 PIN을 정하고 잠금을 켠다 (지금 쓰는 중이니 바로 잠기진 않는다).
  Future<void> enableLock(String pin) async {
    await _enable(pin);
    emit(state.copyWith(enabled: true, locked: false));
  }

  /// 현재 PIN이 맞으면 잠금을 끈다. 맞으면 true.
  Future<bool> disableLock(String pin) async {
    if (!await _disable(pin)) return false;
    _savedBiometric = false;
    emit(
      state.copyWith(
        enabled: false,
        biometricEnabled: false,
        locked: false,
        failedAttempts: 0,
        clearCooldown: true,
      ),
    );
    return true;
  }

  /// 설정에서 본인 확인용으로 현재 PIN이 맞는지만 본다 (잠금 상태는 건드리지 않는다).
  Future<bool> checkPin(String pin) => _verify(pin);

  /// 설정에서 본인 확인용으로 생체 인증을 한 번 묻는다.
  /// 생체 인증을 쓰지 않는 상태면 false.
  Future<bool> confirmWithBiometric(String reason) async {
    if (!state.biometricEnabled) return false;
    return _authenticateBiometric(reason);
  }

  /// 본인 확인(PIN · 생체)을 마친 뒤 잠금을 끈다.
  Future<void> turnOffLock() async {
    await _turnOff(const NoParams());
    _savedBiometric = false;
    emit(
      state.copyWith(
        enabled: false,
        biometricEnabled: false,
        locked: false,
        failedAttempts: 0,
        clearCooldown: true,
      ),
    );
  }

  /// 본인 확인을 마친 뒤 PIN을 새 값으로 바꾼다. 잠금 · 생체 설정은 그대로.
  Future<void> changePin(String newPin) => _enable(newPin);

  /// 생체 인증 사용을 켜고 끈다. 켤 때는 먼저 한 번 인증해 본인 확인을 한다.
  /// 켜기에 실패하면 false.
  Future<bool> setBiometricEnabled(bool value, {required String reason}) async {
    if (!state.enabled) return false;
    if (value) {
      if (!state.biometricAvailable) return false;
      if (!await _authenticateBiometric(reason)) return false;
    }
    await _setBiometric(value);
    _savedBiometric = value;
    emit(state.copyWith(biometricEnabled: value));
    return true;
  }
}
