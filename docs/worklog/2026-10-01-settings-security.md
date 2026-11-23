# 설정 보안 섹션 · 앱 잠금

- 날짜: 2026-10-01
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치: `feature/settings-security` (`feature/playlist-card` 위)
- 상세 기능: 설정 · 보안 (알림 곡 정보 숨기기 #32 이동, 앱 잠금)

## 한 일
- 설정에 **보안** 섹션 추가. 재생 섹션의 "알림에 곡 정보 숨기기"를 여기로 옮겼다 (재생 섹션 삭제, 동작은 그대로 자리 표시).
- **앱 잠금**: 스위치를 켜면 PIN(4~6자리)을 두 번 입력해 정한다. 켜져 있으면 앱을 열 때 잠금 화면(PIN 키패드)이 뜬다. 끌 때는 현재 PIN이 필요하다.
- **생체 인증(선택)**: 앱 잠금이 켜져 있고 기기에 지문 · 얼굴이 등록돼 있으면 "지문 · 얼굴로 열기" 스위치가 나온다. 켜 두면 앱을 열 때 먼저 생체 인증을 묻고, 키패드의 지문 버튼으로 다시 부를 수 있다.
- **PIN 바꾸기** 줄: 현재 PIN(또는 생체 인증)을 확인한 뒤 새 PIN을 두 번 입력해 교체. 잠금 끄기도 같은 확인 (현재 PIN 또는 생체 인증).
- PIN은 해시만 보안 저장소에 저장. 5번 연속 틀리면 30초 입력 정지.
- 새 공통 컴포넌트 `PinPad` (design-system.md에 추가).

## 바꾼 설정
- 패키지 추가: `local_auth`, `flutter_secure_storage`, `crypto` (windows 플러그인 등록 파일 자동 갱신).
- Android: `MainActivity` → `FlutterFragmentActivity`, `USE_BIOMETRIC` 권한, `LaunchTheme` 부모 → `Theme.AppCompat.DayNight.NoActionBar` (values · values-night).
- 문구(ARB ko · en) 추가, `settingsPlayback` 삭제. 결정 D-026.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (cubit 9 + 위젯 9 추가), `flutter build apk --debug`.
- 기기에서의 생체 인증 · 키스토어 동작은 실제 기기로 직접 확인하지 못함.

## 남은 일 · 질문
- 백그라운드에서 돌아올 때 다시 잠그기는 하지 않음 (D-026).
- 폴더 목록 · 서버 주소 · 테마 미리보기 변경은 별도 작업.
