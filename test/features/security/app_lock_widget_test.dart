import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';

import '../../helpers/fakes.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String at = Routes.settings,
  MemoryAppLockRepository? lock,
  FakeBiometricAuthenticator? biometric,
}) async {
  await setUpTestDependencies(appLock: lock, biometric: biometric);
  tester.view.physicalSize = const Size(1170, 7000);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(MusicApp(initialLocation: at));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(PinPad), matching: find.text(d)).last,
    );
    await tester.pump();
  }
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.text('확인'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('설정의 보안 섹션에 앱 잠금과 알림 곡 정보 숨기기가 있다', (tester) async {
    await _pumpApp(tester);
    expect(find.text('보안'), findsOneWidget);
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('알림에 곡 정보 숨기기'), findsOneWidget);
    // 알림 설정은 재생 섹션이 아니라 보안으로 옮겼다.
    expect(find.text('재생'), findsNothing);
    // 잠금이 꺼져 있으면 생체 인증 줄은 없다.
    expect(find.text('지문 · 얼굴로 열기'), findsNothing);
  });

  testWidgets('앱 잠금을 켜면 PIN을 두 번 입력해 저장한다', (tester) async {
    final lock = MemoryAppLockRepository();
    await _pumpApp(tester, lock: lock);

    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    expect(find.text('PIN 정하기'), findsOneWidget);

    await _type(tester, '1234');
    await _submit(tester);
    expect(find.text('PIN 한 번 더'), findsOneWidget);

    await _type(tester, '1234');
    await _submit(tester);
    expect(find.text('보안'), findsOneWidget);
    expect(lock.pin, '1234');
    expect(
      tester.widget<AppSwitch>(find.byType(AppSwitch).first).value,
      isTrue,
    );
  });

  testWidgets('확인 PIN이 다르면 처음부터 다시 정한다', (tester) async {
    final lock = MemoryAppLockRepository();
    await _pumpApp(tester, lock: lock);

    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    await _type(tester, '1234');
    await _submit(tester);
    await _type(tester, '1235');
    await _submit(tester);

    expect(find.text('PIN이 서로 달라요. 처음부터 다시 정해 주세요.'), findsOneWidget);
    expect(find.text('PIN 정하기'), findsOneWidget);
    expect(lock.pin, isNull);
  });

  testWidgets('PIN은 4자리 미만이면 확인할 수 없다', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    await _type(tester, '123');
    await _submit(tester);
    expect(find.text('PIN 정하기'), findsOneWidget);
  });

  testWidgets('잠금이 켜져 있으면 앱을 열 때 PIN을 묻고, 맞으면 열린다', (tester) async {
    await _pumpApp(tester, lock: MemoryAppLockRepository(pin: '1234'));
    expect(find.text('잠겨 있어요'), findsOneWidget);

    await _type(tester, '0000');
    await _submit(tester);
    expect(find.text('PIN이 달라요.'), findsOneWidget);
    expect(find.text('잠겨 있어요'), findsOneWidget);

    await _type(tester, '1234');
    await _submit(tester);
    expect(find.text('잠겨 있어요'), findsNothing);
    expect(find.text('보안'), findsOneWidget);
  });

  testWidgets('생체 인증을 켜 둔 기기는 열자마자 생체 인증으로 푼다', (tester) async {
    final bio = FakeBiometricAuthenticator(available: true);
    await _pumpApp(
      tester,
      lock: MemoryAppLockRepository(pin: '1234', biometric: true),
      biometric: bio,
    );
    expect(bio.calls, 1);
    expect(find.text('잠겨 있어요'), findsNothing);
  });

  testWidgets('PIN 바꾸기: 현재 PIN 확인 뒤 새 PIN을 두 번 입력한다', (tester) async {
    final lock = MemoryAppLockRepository(pin: '1234');
    await _pumpApp(tester, lock: lock);
    await _type(tester, '1234');
    await _submit(tester);

    await tester.tap(find.text('PIN 바꾸기'));
    await tester.pumpAndSettle();
    expect(find.text('현재 PIN'), findsOneWidget);

    await _type(tester, '0000');
    await _submit(tester);
    expect(find.text('PIN이 달라요.'), findsOneWidget);
    expect(lock.pin, '1234');

    await _type(tester, '1234');
    await _submit(tester);
    expect(find.text('PIN 정하기'), findsOneWidget);
    await _type(tester, '2468');
    await _submit(tester);
    await _type(tester, '2468');
    await _submit(tester);

    expect(find.text('보안'), findsOneWidget);
    expect(lock.pin, '2468');
  });

  testWidgets('PIN 바꾸기 · 끄기: 생체 인증으로 현재 PIN을 대신 확인한다', (tester) async {
    final bio = FakeBiometricAuthenticator(available: true);
    final lock = MemoryAppLockRepository(pin: '1234', biometric: true);
    await _pumpApp(tester, lock: lock, biometric: bio);
    // 잠금 화면은 생체 인증으로 풀린다 (1회).
    expect(bio.calls, 1);

    // 바꾸기: 화면을 열면 생체 인증이 한 번 더 불려 새 PIN 단계로 넘어간다.
    await tester.tap(find.text('PIN 바꾸기'));
    await tester.pumpAndSettle();
    expect(bio.calls, 2);
    expect(find.text('PIN 정하기'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(lock.pin, '1234');

    // 끄기: 생체 인증만으로 꺼진다.
    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    expect(bio.calls, 3);
    expect(lock.pin, isNull);
  });

  testWidgets('설정에서 잠금을 끄려면 현재 PIN이 필요하다', (tester) async {
    final lock = MemoryAppLockRepository(pin: '1234');
    await _pumpApp(tester, lock: lock);
    await _type(tester, '1234');
    await _submit(tester);

    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    expect(find.text('현재 PIN'), findsOneWidget);

    await _type(tester, '9999');
    await _submit(tester);
    expect(find.text('PIN이 달라요.'), findsOneWidget);
    expect(lock.pin, '1234');

    await _type(tester, '1234');
    await _submit(tester);
    expect(lock.pin, isNull);
    expect(
      tester.widget<AppSwitch>(find.byType(AppSwitch).first).value,
      isFalse,
    );
  });
}
