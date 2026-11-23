# 내 재생목록 로그인 안내 · 구글 설정 안내

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/youtube-login-prompt`

## 한 일
- 로그아웃 상태에서 "내 재생목록"을 누르면 로그인 여부를 묻는 창을 띄우고 허용 시 로그인 → 목록 불러오기 (D-078).
- 클라이언트 ID가 없을 때 설정 · 가져오기 화면 문구에 빠진 dart-define 이름 표시.
- `docs/google-login-setup.md`, `dart_defines.example.json`, `.vscode/launch.json` 추가.

## 바꾼 설정
- `.gitignore`에 `dart_defines.local.json` 추가, `.vscode/launch.json` 신규, ARB 문구(`settingsAccountNotConfigured`는 `{keys}` 인자 추가).

## 확인
- `flutter analyze` · `flutter test` (아래 보고 참고).

## 남은 일 · 질문
- 실제 구글 로그인은 클라이언트 ID를 넣은 기기에서 직접 확인해야 한다.
