# Android 구글 로그인 유지 (앱을 껐다 켜도)

- 날짜: 2026-10-26
- 분류: 앱 (수정) · 문서
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/android-keep-google-login` (기반: `develop`)
- 상세 기능: 내 재생목록 가져오기 (구글 로그인)

## 한 일
- D-079의 이유 확인: google_sign_in(Android)의 가벼운 로그인은 앱이 허락받은 계정이 없으면 기기 전체 계정 고르기 창을 띄운다. 그래서 시작 때 부르지 않았고, 그 대가로 앱을 끄면 로그아웃됐다.
- `GoogleSignInAuthSource`: 로그인 성공 시 `account.google.signedIn` 표시를 보안 저장소에 남기고, `restore()`는 표시가 있을 때만 `attemptLightweightAuthentication`을 부른다. 표시가 없으면 구글을 부르지 않는다.
- 로그아웃은 표시를 지운다. 가벼운 로그인이 계정을 못 찾으면 표시를 지우고, 일시적 오류면 표시를 남긴다.
- 결정 D-124 기록, D-079에 갱신 표시.

## 바꾼 설정
- `pubspec.yaml`: dev_dependencies에 `google_sign_in_platform_interface: ^3.1.0` (테스트의 가짜 플랫폼용, 잠금 파일 버전 그대로).

## 확인
- `test/features/account/google_sign_in_auth_source_test.dart` 5건: 표시 없으면 구글 호출 0회, 로그인 후 복원, 로그아웃 후 복원 안 함, 계정 없으면 표시 삭제, 일시 오류면 표시 유지.
- `flutter analyze` 경고 0, `flutter test` 전체 통과.

## 남은 일 · 질문
- 실제 Android 기기에서는 확인하지 못했다. 로그인 → 앱 완전 종료 → 재실행 시 설정에 로그인 상태가 보이는지, 로그인한 적 없는 기기에서 창이 뜨지 않는지 확인이 필요하다.
- 표시는 있는데 허락이 사라진 드문 경우엔 그 실행에서 한 번 계정 고르기 창이 뜰 수 있다 (D-124).
