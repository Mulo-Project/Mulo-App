# 지문 인증이 갑자기 안 되는 문제 (시작 직후 "없음" 굳음)

- 날짜: 2026-10-15
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `fix/biometric-recheck-on-resume`
- 상세 기능: 설정 보안 · 앱 잠금

## 한 일
- 원인: `chore/app-optimization`(#110)의 `MuloEngine`이 엔진을 화면보다 먼저 만들고 Dart를 바로 시작한다.
  `AppLockCubit.load()`의 생체 인증 확인이 화면(Activity)이 엔진에 붙기 전에 나가면 local_auth_android가
  `biometricManager`가 없어 "등록된 생체 없음"으로 답하고, 그 값이 앱이 죽을 때까지 굳어 지문 버튼 · 자동 인증이 사라진다.
- `AppLockCubit.refreshBiometric()` 추가: 저장된 사용 여부(`_savedBiometric`)를 따로 쥐고 가용성만 다시 본다.
- 앞으로 돌아올 때(`LockGate`)와 잠금 · 본인 확인 화면이 지문을 묻기 직전에 다시 본다.

## 바꾼 설정
- 없음 (Dart만).

## 확인
- `flutter analyze` 경고 0, `flutter test test/features/security` 통과 (재확인 테스트 추가).

## 남은 일 · 질문
- 실기기(지문)에서 #110 빌드로 재현 · 해결 확인은 사용자가 해야 한다.
