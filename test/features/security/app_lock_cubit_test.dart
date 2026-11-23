import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/security/domain/entities/app_lock_settings.dart';
import 'package:music_download_play_app/features/security/domain/usecases/app_lock_usecases.dart';
import 'package:music_download_play_app/features/security/presentation/bloc/app_lock_cubit.dart';

import '../../helpers/fakes.dart';

AppLockCubit _cubit(
  MemoryAppLockRepository repo,
  FakeBiometricAuthenticator bio, {
  DateTime Function()? now,
}) => AppLockCubit(
  load: LoadAppLock(repo),
  enable: EnableAppLock(repo),
  disable: DisableAppLock(repo),
  turnOff: TurnOffAppLock(repo),
  verify: VerifyPin(repo),
  setBiometric: SetBiometric(repo),
  isBiometricAvailable: IsBiometricAvailable(bio),
  authenticateBiometric: AuthenticateBiometric(bio),
  now: now ?? DateTime.now,
);

void main() {
  test('PIN은 4~6자리 숫자만', () {
    expect(AppLockSettings.isValidPin('1234'), isTrue);
    expect(AppLockSettings.isValidPin('123456'), isTrue);
    expect(AppLockSettings.isValidPin('123'), isFalse);
    expect(AppLockSettings.isValidPin('1234567'), isFalse);
    expect(AppLockSettings.isValidPin('12a4'), isFalse);
  });

  test('잠금이 꺼져 있으면 열려 있고, 불러오기 전에는 loaded가 false', () async {
    final c = _cubit(MemoryAppLockRepository(), FakeBiometricAuthenticator());
    addTearDown(c.close);
    expect(c.state.loaded, isFalse);
    await c.load();
    expect(c.state.loaded, isTrue);
    expect(c.state.locked, isFalse);
    expect(c.state.enabled, isFalse);
  });

  test('잠금이 켜져 있으면 잠근 채로 시작하고 PIN으로 푼다', () async {
    final c = _cubit(
      MemoryAppLockRepository(pin: '1234'),
      FakeBiometricAuthenticator(),
    );
    addTearDown(c.close);
    await c.load();
    expect(c.state.locked, isTrue);

    expect(await c.unlock('0000'), isFalse);
    expect(c.state.locked, isTrue);
    expect(await c.unlock('1234'), isTrue);
    expect(c.state.locked, isFalse);
  });

  test('5번 이어서 틀리면 잠시 입력을 막는다', () async {
    var clock = DateTime(2026, 10, 1, 12);
    final c = _cubit(
      MemoryAppLockRepository(pin: '1234'),
      FakeBiometricAuthenticator(),
      now: () => clock,
    );
    addTearDown(c.close);
    await c.load();
    for (var i = 0; i < AppLockCubit.maxAttempts; i++) {
      expect(await c.unlock('0000'), isFalse);
    }
    expect(c.inCooldown, isTrue);
    // 멈춘 동안은 맞는 PIN도 받지 않는다.
    expect(await c.unlock('1234'), isFalse);
    expect(c.state.locked, isTrue);

    clock = clock.add(AppLockCubit.cooldown + const Duration(seconds: 1));
    expect(c.inCooldown, isFalse);
    expect(await c.unlock('1234'), isTrue);
  });

  test('enableLock은 PIN을 저장하고 지금 화면은 잠그지 않는다', () async {
    final repo = MemoryAppLockRepository();
    final c = _cubit(repo, FakeBiometricAuthenticator());
    addTearDown(c.close);
    await c.load();
    await c.enableLock('4321');
    expect(repo.pin, '4321');
    expect(c.state.enabled, isTrue);
    expect(c.state.locked, isFalse);
    expect(() => c.enableLock('12'), throwsArgumentError);
  });

  test('disableLock은 현재 PIN이 맞을 때만 끈다', () async {
    final repo = MemoryAppLockRepository(pin: '1234', biometric: true);
    final c = _cubit(repo, FakeBiometricAuthenticator(available: true));
    addTearDown(c.close);
    await c.load();
    await c.unlock('1234');

    expect(await c.disableLock('9999'), isFalse);
    expect(c.state.enabled, isTrue);
    expect(await c.disableLock('1234'), isTrue);
    expect(c.state.enabled, isFalse);
    expect(c.state.biometricEnabled, isFalse);
    expect(repo.pin, isNull);
    expect(repo.biometric, isFalse);
  });

  test('본인 확인 뒤 잠금 끄기 · PIN 바꾸기 (생체 확인 경로 포함)', () async {
    final repo = MemoryAppLockRepository(pin: '1234', biometric: true);
    final bio = FakeBiometricAuthenticator(available: true);
    final c = _cubit(repo, bio);
    addTearDown(c.close);
    await c.load();
    await c.unlock('1234');

    expect(await c.checkPin('0000'), isFalse);
    expect(await c.checkPin('1234'), isTrue);
    expect(await c.confirmWithBiometric('r'), isTrue);

    await c.changePin('5678');
    expect(repo.pin, '5678');
    expect(c.state.enabled, isTrue);
    expect(c.state.biometricEnabled, isTrue);

    await c.turnOffLock();
    expect(repo.pin, isNull);
    expect(c.state.enabled, isFalse);
    expect(c.state.locked, isFalse);
    // 생체를 쓰지 않는 상태에서는 확인 경로가 막힌다.
    expect(await c.confirmWithBiometric('r'), isFalse);
  });

  test('생체 인증: 켤 때 한 번 인증하고, 켜져 있으면 생체로 풀 수 있다', () async {
    final repo = MemoryAppLockRepository(pin: '1234');
    final bio = FakeBiometricAuthenticator(available: true);
    final c = _cubit(repo, bio);
    addTearDown(c.close);
    await c.load();
    expect(c.state.biometricAvailable, isTrue);
    expect(c.state.biometricEnabled, isFalse);
    expect(await c.unlockWithBiometric('r'), isFalse);

    bio.succeeds = false;
    expect(await c.setBiometricEnabled(true, reason: 'r'), isFalse);
    expect(c.state.biometricEnabled, isFalse);

    bio.succeeds = true;
    expect(await c.setBiometricEnabled(true, reason: 'r'), isTrue);
    expect(repo.biometric, isTrue);

    expect(c.state.locked, isTrue);
    expect(await c.unlockWithBiometric('r'), isTrue);
    expect(c.state.locked, isFalse);
  });

  test('생체 인증을 쓸 수 없는 기기에서는 켜지지 않는다', () async {
    final c = _cubit(
      MemoryAppLockRepository(pin: '1234'),
      FakeBiometricAuthenticator(available: false),
    );
    addTearDown(c.close);
    await c.load();
    expect(await c.setBiometricEnabled(true, reason: 'r'), isFalse);
    expect(c.state.biometricEnabled, isFalse);
  });

  test('시작 때 생체 인증이 "없음"으로 답해도 다시 보면 저장된 설정이 살아난다', () async {
    final repo = MemoryAppLockRepository(pin: '1234', biometric: true);
    final bio = FakeBiometricAuthenticator(available: false);
    final c = _cubit(repo, bio);
    addTearDown(c.close);
    await c.load();
    expect(c.state.biometricAvailable, isFalse);
    expect(c.state.biometricEnabled, isFalse);

    bio.available = true;
    await c.refreshBiometric();
    expect(c.state.biometricAvailable, isTrue);
    expect(c.state.biometricEnabled, isTrue);
    expect(await c.unlockWithBiometric('r'), isTrue);
  });
}
